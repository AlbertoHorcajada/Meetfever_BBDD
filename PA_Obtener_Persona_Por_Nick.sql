USE [MeetFever]
GO
/****** Object:  StoredProcedure [dbo].[PA_Obtener_Persona_Por_Nick]    Script Date: 15/06/2022 11:15:02 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- ============================================
-- Author: Alberto Horcajada
-- Create date: 25/04/2022
-- Descrption: Este es un procedimiento almacenado que devuelve todos los datos de un usuario Persona determinado por un nickName
-- ============================================

	ALTER PROCEDURE [dbo].[PA_Obtener_Persona_Por_Nick]
	
		@JSON_IN NVARCHAR(MAX), 
		@JSON_OUT NVARCHAR(MAX) OUTPUT,
		@INVOKER INT,
		@RETCODE INT OUTPUT,
		@MENSAJE NVARCHAR(MAX) OUTPUT

	AS
		SET @RETCODE = 0
		SET @MENSAJE = 'Persona encontrada'
		DECLARE @NICK VARCHAR(30)

		DECLARE @JSON_ELIMINADO NVARCHAR(MAX)
		DECLARE @ELIMINADO BIT
		-- Recuperacion del ID del JSON entrante
	BEGIN TRY

		SELECT @NICK = Nick
			FROM
				OPENJSON (@JSON_IN) WITH (Nick VARCHAR(30) '$.Nick')
		-- Comrpobaciones de ese ID
		
		IF (@NICK IS NULL)
			BEGIN
				SET @RETCODE = 1
				SET @MENSAJE = 'Nick nulo'
				SET @JSON_OUT = '{"Exito":false}'
			END

		IF (@NICK = '')
			BEGIN
				SET @RETCODE = 2
				SET @MENSAJE = 'Nick vacio'
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
			WHERE u.Nick = @NICK
			FOR JSON PATH, WITHOUT_ARRAY_WRAPPER)


		-- Dos comprobaciones para asegurarnos de que está bien el JSON

		IF (@JSON_OUT = '')
			BEGIN
				SET @RETCODE = 5
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
					SELECT u.Eliminado
					FROM Usuario u
					WHERE Nick = @NICK
				FOR JSON AUTO)

				SELECT @ELIMINADO = Eliminado
					FROM
						OPENJSON (@JSON_ELIMINADO) WITH (Eliminado BIT '$.Eliminado')

				IF (@ELIMINADO = 1)
					BEGIN	

						SET @JSON_OUT = null
						SET @RETCODE = 6
						SET @MENSAJE = 'Usuario eliminado de forma logica'
						SET @JSON_OUT = '{"Exito":false}'

					END

			END

		

		

	END TRY
	BEGIN CATCH
		SET @MENSAJE = SUBSTRING(ERROR_MESSAGE(), 1, 8000)
		SET @RETCODE = -1
	END CATCH
