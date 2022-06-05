USE [MeetFever]
GO
/****** Object:  StoredProcedure [dbo].[PA_Obtener_Entradas_Por_Usuario]    Script Date: 05/06/2022 18:06:45 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- ============================================
-- Author: Alberto Horcajada
-- Create date: 24/04/2022
-- Descrption: Este es un procedimiento almacenado que devuelve todas las entradas compradaas de una experiencia
-- ============================================

	ALTER PROCEDURE [dbo].[PA_Obtener_Entradas_Por_Usuario]
	
		@JSON_IN NVARCHAR(MAX), 
		@JSON_OUT NVARCHAR(MAX) OUTPUT,
		@INVOKER INT,
		@RETCODE INT OUTPUT,
		@MENSAJE NVARCHAR(MAX) OUTPUT

	AS
		SET @RETCODE = 0
		SET @MENSAJE = 'entradas encontradas exitosamente'
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
				SET @MENSAJE = 'ID no valido, numero negativo'
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
			
			SELECT DISTINCT Entrada_Persona.Id,
			-- Paso la persona que se encargó de comprar la entrada

			(Select Usuario.Id AS 'Id',
					Usuario.Correo AS 'Correo',
					Usuario.Contrasena AS 'Contrasena',
					Usuario.Nick AS 'Nick',
	--				Usuario.Foto_Fondo AS 'Foto_Fondo',
	--				Usuario.Foto_Perfil AS 'Foto_Perfil',
					Usuario.Telefono AS 'Telefono',
					Usuario.Frase AS 'Frase',
					Persona.Dni AS 'Dni',
					Persona.Nombre AS 'Nombre',
					Persona.Apellido1 AS 'Apellido1',
					Persona.Apellido2 AS 'Apellido2',
					Sexo.Id AS 'Sexo.Id',
					Sexo.Sexo AS 'Sexo.Sexo',
					Persona.Fecha_Nacimiento AS 'Fecha_Nacimiento'
				
					FROM Usuario INNER JOIN Persona ON (Persona.Id = Usuario.Id)
					WHERE Persona.Id IN (select Entrada_Persona.Id_Persona
						FROM Entrada_Persona e INNER JOIN Persona ON (Persona.Id = e.Id_Persona)
							WHERE e.Id = Entrada_Persona.Id)
							FOR JSON AUTO, WITHOUT_ARRAY_WRAPPER) AS 'Persona',





			-- Paso la experiencia de la que se compra la entrada
			Experiencia.Id AS 'Experiencia.Id',
			Experiencia.Titulo AS 'Experiencia.Titulo',
			Experiencia.Descripcion AS 'Experiencia.Descripcion',
			Experiencia.Fecha_Celebracion AS 'Experiencia.Fecha_Celebracion',
			Experiencia.Precio AS 'Experiencia.Precio',
			Experiencia.Aforo AS 'Experiencia.Aforo',
			Experiencia.Foto AS 'Experiencia.Foto',
			-- Como una Experiencia contiene una empresa le tengo que mandar el objeto de la empresa
			-- ESTAMOS ASUMIENDO QUE ES UNA EMPRESA, cosa que deberia ser siempre asi
			(Select Usuario.Id AS 'Id',
					Usuario.Correo AS 'Correo',
					Usuario.Contrasena AS 'Contrasena',
					Usuario.Nick AS 'Nick',
	--				Usuario.Foto_Fondo AS 'Foto_Fondo',
	--				Usuario.Foto_Perfil AS 'Foto_Perfil',
					Usuario.Telefono AS 'Telefono',
					Usuario.Frase AS 'Frase',
					Empresa.Nombre_Empresa AS 'Nombre_Empresa',
					Empresa.Cif AS 'Cif',
					Empresa.Direccion_Facturacion AS 'Direccion_Facturacion',
					Empresa.Direccion_Fiscal AS 'Direccion_Fiscal',
					Empresa.Nombre_Persona AS 'Nombre_Persona',
					Empresa.Apellido1_Persona AS 'Apellido1_Persona',
					Empresa.Apellido2_Persona AS 'Apellido2_Persona',
					Empresa.Dni_Persona  AS 'Dni_Persona'
				
					FROM Usuario INNER JOIN Empresa ON (Empresa.Id = Usuario.Id)
					WHERE Usuario.Id IN (select Experiencia.Id_Empresa
						FROM Experiencia INNER JOIN Empresa ON (Empresa.Id = Experiencia.Id_Empresa)
							WHERE Experiencia.Id = Entrada_Persona.Id_Experiencia)
							FOR JSON PATH) AS 'Experiencia.Empresa',

		
			-- Resto de datos que contiene una entrada
			Entrada_Persona.Fecha,

			-- TIENES QUE DEVOLVER UNA LISTA DE ESTOS, NO SOLO UNO, FIJATE EN EL JSON
			Entrada_Persona.Nombre,
			Entrada_Persona.Apellido1,
			Entrada_Persona.Apellido2,
			Entrada_Persona.Dni,
			-- TIENES QUE DEVOLVER UNA LISTA DE ESTOS, NO SOLO UNO, FIJATE EN EL JSON

			Entrada_Persona.Id_paypal
			

			FROM Entrada_Persona INNER JOIN Persona on (Entrada_Persona.Id_Persona = Persona.Id) 
					INNER JOIN Usuario ON (Usuario.Id = Persona.Id)
					INNER JOIN Experiencia ON (Experiencia.Id = Entrada_Persona.Id_Experiencia)
					INNER JOIN Sexo ON (Sexo.Id = Persona.Sexo)
			WHERE Entrada_Persona.Id_Persona = @ID_USUARIO and Entrada_Persona.eliminado = 0	
			FOR JSON PATH) -- Y ESTO TIENE QUE SER WITHOUT ARRAY WRAPPER


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
				SET @MENSAJE = 'Experiencias no encontradas'
				SET @JSON_OUT = '{"Exito":false}'
			END
		
	END
	END TRY
	BEGIN CATCH
		SET @MENSAJE = SUBSTRING(ERROR_MESSAGE(), 1, 8000)
		SET @RETCODE = -1
		SET @JSON_OUT = '{"Exito":false}'
	END CATCH
