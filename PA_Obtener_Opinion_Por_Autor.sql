USE [MeetFever]
GO
/****** Object:  StoredProcedure [dbo].[PA_Obtener_Opinion_Por_Autor]    Script Date: 05/06/2022 18:08:06 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- ============================================
-- Author: Alberto Horcajada
-- Create date: 24/04/2022
-- Descrption: Este es un procedimiento almacenado que devuelve todos los datos de una opinion por la ID de un autor
-- ============================================

	ALTER PROCEDURE [dbo].[PA_Obtener_Opinion_Por_Autor]
	
		@JSON_IN NVARCHAR(MAX), 
		@JSON_OUT NVARCHAR(MAX) OUTPUT,
		@INVOKER INT,
		@RETCODE INT OUTPUT,
		@MENSAJE NVARCHAR(MAX) OUTPUT

	AS
		SET @RETCODE = 0
		SET @MENSAJE = 'Opiniones encontradas exitosamente'
		DECLARE @ID_AUTOR INT
		DECLARE @JSON_PRUEBA NVARCHAR(MAX)
		DECLARE @ID_USUARIO	INT

		-- Recuperacion del ID del JSON entrante
	BEGIN TRY

		SELECT @ID_AUTOR = Id_Autor, @ID_USUARIO = Id_Usuario
			FROM
				OPENJSON (@JSON_IN) WITH (Id_Autor INT '$.Id_Autor', Id_Usuario INT '$.Id_Usuario')
		-- Comrpobaciones de ese ID
		
		IF (@ID_AUTOR IS NULL)
			BEGIN
				SET @RETCODE = 1
				SET @MENSAJE = 'ID nulo'
				SET @JSON_OUT = '{"Exito":false}'
			END

		IF (@ID_AUTOR = '')
			BEGIN
				SET @RETCODE = 2
				SET @MENSAJE = 'ID vacio'
				SET @JSON_OUT = '{"Exito":false}'
			END

		IF (@ID_AUTOR <0)
			BEGIN
				SET @RETCODE = 3
				SET @MENSAJE = 'ID no valido, numero negativo'
				SET @JSON_OUT = '{"Exito":false}'
			END

					IF(@RETCODE = 0)
			BEGIN
				SET @JSON_PRUEBA = (
					SELECT u.Id
						FROM Usuario u
						where u.Id = @ID_AUTOR AND Eliminado = 0
				FOR JSON PATH)
				
				IF (@JSON_PRUEBA IS NULL)
					BEGIN
						SET @RETCODE = 4
						SET @MENSAJE = 'no existe el usuario'
						SET @JSON_OUT = '{"Exito":false}'
					END

			END


		IF (@ID_USUARIO IS NULL)
			BEGIN
				SET @RETCODE = 5
				SET @MENSAJE = 'No hay Id del Usuario'
				SET @JSON_OUT = '{"Exito":false}'
			END

		SET NOCOUNT ON;

		-- Crear JSON de respuesta a raiz de la consulta

		IF (@RETCODE = 0)
			BEGIN
				SET @JSON_OUT = (
			
					SELECT o.Id,
					o.Titulo,
					o.Descripcion,
					o.Fecha,
			-- solo el genérico porque el 95% de los casos no necesito al hijo
					u.id AS 'Autor.Id',
					u.Correo AS 'Autor.Correo',
					u.Contrasena AS 'Autor.Contrasena',
					u.Nick AS 'Autor.Nick',
					u.Foto_Fondo AS 'Autor.Foto_Fondo',
					u.Foto_Perfil AS 'Autor.Foto_Perfil',
					u.Telefono AS 'Autor.Telefono',
					u.Frase AS 'Autor.Frase',
					o.Id_Empresa,
					o.Id_Experiencia, -- importante el emoji
					e.Id AS 'Emoticono.Id',
					e.Emoji AS 'Emoticono.Emoji',
					CAST(
						CASE
							WHEN ((select id from MeGusta mg WHERE mg.Id_Usuario = @ID_USUARIO AND mg.Id_Opinion = o.Id) IS NULL)
								THEN 0
							ELSE 1
						END AS bit)
						AS 'Like',
					(select COUNT(distinct mg.Id_Usuario) from MeGusta mg where mg.Id_Opinion = o.Id) AS 'Numero_Likes'
					FROM Opinion o INNER JOIN Usuario u ON (u.Id = o.Id_Autor)
					INNER JOIN Emoticono e
					ON (e.id = o.Emoticono)
					WHERE o.Id_Autor = @ID_AUTOR and o.eliminado = 0
					ORDER BY o.Id DESC
				FOR JSON PATH)
			

		-- Dos comprobaciones para asegurarnos de que está bien el JSON

				IF (@JSON_OUT = '')
					BEGIN
						SET @RETCODE = 6
						SET @MENSAJE = 'JSON vacio'
						SET @JSON_OUT = '{"Exito":false}'
					END


				IF(@JSON_OUT IS NULL)
					BEGIN
						SET @RETCODE = 7
						SET @MENSAJE = 'Opiniones no encontradas'
						SET @JSON_OUT = '{"Exito":false}'
					END
		END

	END TRY
	BEGIN CATCH
		SET @MENSAJE = SUBSTRING(ERROR_MESSAGE(), 1, 8000)
		SET @RETCODE = -1
		SET @JSON_OUT = '{"Exito":false}'
	END CATCH
