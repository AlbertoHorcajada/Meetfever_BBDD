USE [MeetFever]
GO
/****** Object:  StoredProcedure [dbo].[PA_Obtener_Entradas_Por_Usuario]    Script Date: 15/06/2022 11:12:32 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- ============================================
-- Author: Alberto Horcajada
-- Create date: 24/04/2022
-- Descrption: Este es un procedimiento almacenado que devuelve todas las entradas compradas de un usuario para crear
-- ============================================

	ALTER PROCEDURE [dbo].[PA_Obtener_Entradas_Por_Usuario]
	
		@JSON_IN NVARCHAR(MAX), 
		@JSON_OUT NVARCHAR(MAX) OUTPUT,
		@INVOKER INT,
		@RETCODE INT OUTPUT,
		@MENSAJE NVARCHAR(MAX) OUTPUT

	AS
		SET @RETCODE = 0
		SET @MENSAJE = 'entradas encontradas'
		DECLARE @ID_USUARIO INT

		DECLARE @JSONPRUEBA NVARCHAR(MAX)

		-- Recuperacion del ID del JSON entrante
	BEGIN TRY

		SELECT @ID_USUARIO = Id_Usuario
			FROM
				OPENJSON (@JSON_IN) WITH (Id_Usuario INT '$.Id_Usuario')
		-- Comrpobaciones de ese ID
		
		IF (@ID_USUARIO IS NULL)
			BEGIN
				SET @RETCODE = 1
				SET @MENSAJE = 'ID nulo'
				SET @JSON_OUT = '{"Exito":false}'
			END

		ELSE IF (@ID_USUARIO = '')
			BEGIN
				SET @RETCODE = 2
				SET @MENSAJE = 'ID vacio'
				SET @JSON_OUT = '{"Exito":false}'
			END

		ELSE IF (@ID_USUARIO <0)
			BEGIN
				SET @RETCODE = 3
				SET @MENSAJE = 'ID menor que 0'
				SET @JSON_OUT = '{"Exito":false}'
			END

		IF (@RETCODE = 0)
			BEGIN
				SET @JSONPRUEBA = (
					SELECT Id
					From Persona
					WHERE Id = @ID_USUARIO AND Eliminado = 0
				)

				IF (@JSONPRUEBA IS NULL)
					BEGIN
						SET @RETCODE = 4
						SET @MENSAJE = 'No existe la persona o borrada de forma logica'
						SET @JSON_OUT = '{"Exito":false}'
					END

			END

		SET NOCOUNT ON;

		-- Crear JSON de respuesta a raiz de la consulta
	IF (@RETCODE = 0)
	BEGIN
		SET @JSON_OUT = (
			
			SELECT DISTINCT
				Persona.Nombre AS 'Factura.Nombre_Persona',
				Persona.Apellido1 AS 'Factura.Apellido_1_Persona',
				Persona.Apellido1 AS 'Factura.Apellido_2_Persona',
				Persona.Dni AS 'Factura.Dni_Persona',

				Entrada_Persona.Fecha AS 'Factura.Fecha_Entradas',

				Experiencia.Precio AS 'Factura.Precio',

				Entrada_Persona.Id_paypal AS 'Factura.Id_Transaccion',

				Experiencia.Titulo AS 'Factura.Titulo_Experiencia',
				(
					SELECT Empresa.Id FROM Empresa WHERE Experiencia.Id_Empresa = Empresa.id
				) 
				AS 'Factura.Id_Empresa' ,
				(
					SELECT Empresa.Nombre_Empresa FROM Empresa WHERE Experiencia.Id_Empresa = Empresa.id
				) 
				AS 'Factura.Nombre_Empresa' ,
				(
					SELECT 
						e.Nombre AS 'Titular.Nombre_Titular',
						e.Apellido1 AS 'Titular.Apellido_1_Titular',
						e.Apellido2 AS 'Titular.Apellido_2_Titular'
					FROM Entrada_Persona as e
					WHERE e.Id_paypal = Entrada_Persona.Id_paypal
					FOR JSON PATH
				) AS 'Factura.Titulares'

			FROM Usuario INNER JOIN Persona
			ON(Persona.Id = Usuario.Id)
			INNER JOIN Entrada_Persona
			ON (Entrada_Persona.Id_Persona = Persona.Id)
			INNER JOIN Experiencia
			ON (Experiencia.Id = Entrada_Persona.Id_Experiencia)

			WHERE Usuario.Id = @ID_USUARIO

			-- GROUP BY Entrada_Persona.Id_paypal

			FOR JSON PATH
		
		)

		-- Dos comprobaciones para asegurarnos de que está bien el JSON

		IF (@JSON_OUT = '')
			BEGIN
				SET @RETCODE = 5
				SET @MENSAJE = 'JSON vacio'
				SET @JSON_OUT = '{"Exito":false}'
			END


		IF(@JSON_OUT IS NULL)
			BEGIN
				SET @RETCODE = 6
				SET @MENSAJE = 'Entradas no encontradas'
				SET @JSON_OUT = '{"Exito":false}'
			END
		
	END
	END TRY
	BEGIN CATCH
		SET @MENSAJE = SUBSTRING(ERROR_MESSAGE(), 1, 8000)
		SET @RETCODE = -1
		SET @JSON_OUT = '{"Exito":false}'
	END CATCH
