USE [MeetFever]
GO
/****** Object:  StoredProcedure [dbo].[PA_Obtener_Persona_General]    Script Date: 15/06/2022 11:14:30 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- ============================================
-- Author: Alberto Horcajada
-- Create date: 25/04/2022
-- Descrption: Este es un procedimiento almacenado que devuelve todos los datos de un usuario Persona dada una cadena de caracteres que contenga alguna coincidencia
-- ============================================

	ALTER PROCEDURE [dbo].[PA_Obtener_Persona_General]
	
		@JSON_IN NVARCHAR(MAX), 
		@JSON_OUT NVARCHAR(MAX) OUTPUT,
		@INVOKER INT,
		@RETCODE INT OUTPUT,
		@MENSAJE NVARCHAR(MAX) OUTPUT

	AS
		SET @RETCODE = 0
		SET @MENSAJE = 'Persona encontrada'
		DECLARE @PALABRA VARCHAR(255)

		DECLARE @JSON_ELIMINADO NVARCHAR(MAX)
		DECLARE @ELIMINADO BIT
		-- Recuperacion del ID del JSON entrante
	BEGIN TRY

		SELECT @PALABRA = Palabra
			FROM
				OPENJSON (@JSON_IN) WITH (Palabra VARCHAR(255) '$.Palabra')
		-- Comrpobaciones de ese ID
		
		IF (@PALABRA IS NULL)
			BEGIN
				SET @RETCODE = 1
				SET @MENSAJE = 'Palabra nula'
				SET @JSON_OUT = '{"Exito":false}'
			END

		IF (@PALABRA = '')
			BEGIN
				SET @RETCODE = 2
				SET @MENSAJE = 'Palabra vacia'
				SET @JSON_OUT = '{"Exito":false}'
			END

		SET NOCOUNT ON;

		-- Crear JSON de respuesta a raiz de la consulta

		IF(@RETCODE = 0)
			BEGIN
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
					WHERE u.Eliminado = 0 AND p.Eliminado = 0 
					AND (u.Correo LIKE   '%' +@PALABRA + '%' OR
								u.Nick LIKE   '%' +@PALABRA + '%' OR
								u.Frase LIKE   '%' +@PALABRA + '%' OR
								p.Nombre LIKE   '%' +@PALABRA + '%' OR
								p.Apellido1 LIKE   '%' +@PALABRA + '%'	OR
								p.Apellido2 LIKE   '%' +@PALABRA + '%')

					FOR JSON PATH)


				-- Dos comprobaciones para asegurarnos de que está bien el JSON

				IF (@JSON_OUT = '')
					BEGIN
						SET @RETCODE = 4
						SET @MENSAJE = 'JSON vacio'
						SET @JSON_OUT = '{"Exito":false}'
					END

				IF(@JSON_OUT IS NULL)
					BEGIN
						SET @RETCODE = 5
						SET @MENSAJE = 'Persona no encontrada'
						SET @JSON_OUT = '{"Exito":false}'
					END	

			END

	END TRY
	BEGIN CATCH
		SET @MENSAJE = SUBSTRING(ERROR_MESSAGE(), 1, 8000)
		SET @RETCODE = -1
		SET @JSON_OUT = '{"Exito":false}'
	END CATCH
