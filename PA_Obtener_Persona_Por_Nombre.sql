USE [MeetFever]
GO
/****** Object:  StoredProcedure [dbo].[PA_Obtener_Persona_Por_Nombre]    Script Date: 15/06/2022 11:15:10 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- ============================================
-- Author: Alberto Horcajada
-- Create date: 25/04/2022
-- Descrption: Este es un procedimiento almacenado que devuelve todos los datos de un usuario Persona determinado por un Nombre
-- ============================================

	ALTER PROCEDURE [dbo].[PA_Obtener_Persona_Por_Nombre]
	
		@JSON_IN NVARCHAR(MAX), 
		@JSON_OUT NVARCHAR(MAX) OUTPUT,
		@INVOKER INT,
		@RETCODE INT OUTPUT,
		@MENSAJE NVARCHAR(MAX) OUTPUT

	AS
		SET @RETCODE = 0
		SET @MENSAJE = 'Persona encontrado'
		DECLARE @NOMBRE VARCHAR(50)

		DECLARE @JSON_ELIMINADO NVARCHAR(MAX)
		DECLARE @ELIMINADO BIT
		-- Recuperacion del ID del JSON entrante
	BEGIN TRY

		SELECT @NOMBRE = Nombre
			FROM
				OPENJSON (@JSON_IN) WITH (Nombre VARCHAR(50) '$.Nombre')
		-- Comrpobaciones de ese ID
		
		IF (@NOMBRE IS NULL)
			BEGIN
				SET @RETCODE = 1
				SET @MENSAJE = 'Nombre nulo'
				SET @JSON_OUT = '{"Exito":false}'
			END

		IF (@NOMBRE = '')
			BEGIN
				SET @RETCODE = 2
				SET @MENSAJE = 'Nombre vacio'
				SET @JSON_OUT = '{"Exito":false}'
			END

		SET NOCOUNT ON;

		-- Crear JSON de respuesta a raiz de la consulta

		SET @JSON_OUT = (
			
			SELECT u.Id,
					u.Correo,
					u.Contrasena,
					u.Nick,
					u.Foto_Fondo,
					u.Foto_Perfil,
					u.Telefono,
					u.Frase,
					p.Dni,
					p.Nombre,
					p.Apellido1,
					p.Apellido2,
					s.Id AS 'Sexo.Id',
					s.Sexo AS 'Sexo.Sexo',
					p.Fecha_Nacimiento
			FROM Usuario u INNER JOIN Persona p ON (u.Id = p.Id) INNER JOIN Sexo s ON (p.Sexo = s.Id)
			WHERE p.Nombre = @NOMBRE
			FOR JSON PATH)


		-- Dos comprobaciones para asegurarnos de que está bien el JSON

		IF (@JSON_OUT = '')
			BEGIN
				SET @RETCODE = 3
				SET @MENSAJE = 'JSON vacio'
				SET @JSON_OUT = '{"Exito":false}'
			END

		IF(@JSON_OUT IS NULL)
			BEGIN
				SET @RETCODE = 4
				SET @MENSAJE = 'Persona no encontrada'
				SET @JSON_OUT = '{"Exito":false}'
			END
		ELSE
			BEGIN
				SET @JSON_ELIMINADO = (
					SELECT p.Eliminado
					FROM Persona p
					WHERE Nombre = @NOMBRE
				FOR JSON AUTO)

				SELECT @ELIMINADO = Eliminado
					FROM
						OPENJSON (@JSON_ELIMINADO) WITH (Eliminado BIT '$.Eliminado')

				IF (@ELIMINADO = 1)
					BEGIN	

						SET @JSON_OUT = '{"Exito":false}'
						SET @RETCODE = 5
						SET @MENSAJE = 'Usuario eliminado de forma logica'

					END

			END	

		

		

	END TRY
	BEGIN CATCH
		SET @MENSAJE = SUBSTRING(ERROR_MESSAGE(), 1, 8000)
		SET @RETCODE = -1
		SET @JSON_OUT = '{"Exito":false}'
	END CATCH
