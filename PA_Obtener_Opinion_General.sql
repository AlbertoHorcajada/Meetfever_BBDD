USE [MeetFever]
GO
/****** Object:  StoredProcedure [dbo].[PA_Obtener_Opinion_General]    Script Date: 15/06/2022 11:13:39 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- ============================================
-- Author: Alberto Horcajada
-- Create date: 24/04/2022
-- Descrption: Este es un procedimiento almacenado que devuelve todos los datos de una opinion dado una cadena de cracteres que contenga alguna coincidencia
-- ============================================

	ALTER PROCEDURE [dbo].[PA_Obtener_Opinion_General]
	
		@JSON_IN NVARCHAR(MAX), 
		@JSON_OUT NVARCHAR(MAX) OUTPUT,
		@INVOKER INT,
		@RETCODE INT OUTPUT,
		@MENSAJE NVARCHAR(MAX) OUTPUT

	AS
		SET @RETCODE = 0
		SET @MENSAJE = 'Opinion encontrada'
		DECLARE @PALABRA VARCHAR(255)
		DECLARE @ID_USUARIO	INT

		
		-- Recuperacion del cadena del JSON entrante
	BEGIN TRY

		SELECT @PALABRA = Palabra, @ID_USUARIO = Id_Usuario
			FROM
				OPENJSON (@JSON_IN) WITH (Palabra VARCHAR(255) '$.Palabra', Id_Usuario INT '$.Id_Usuario')
		-- Comrpobaciones de esa cadena
		
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

		IF (@ID_USUARIO IS NULL)
			BEGIN
				SET @RETCODE = 3
				SET @MENSAJE = 'Id_Usuario vacío'
				SET @JSON_OUT = '{"Exito":false}'
			END

		SET NOCOUNT ON;

		-- Crear JSON de respuesta a raiz de la consulta

		IF (@RETCODE = 0)
			BEGIN

				SET @JSON_OUT = (
			
					SELECT DISTINCT o.Id,
					o.Titulo,
					o.Descripcion,
					o.Fecha,
					e.Id AS 'Emoticono.Id',
					e.Emoji AS 'Emoticono.Emoji',
					u.id AS 'Autor.Id',
					u.Correo AS 'Autor.Correo',
					u.Contrasena AS 'Autor.Contrasena',
					u.Nick AS 'Autor.Nick',
					u.Foto_Fondo AS 'Autor.Foto_Fondo',
					u.Foto_Perfil AS 'Autor.Foto_Perfil',
					u.Telefono AS 'Autor.Telefono',
					u.Frase AS 'Autor.Frase',
					o.Id_Empresa,
					o.Id_Experiencia,
					CAST(
					 CASE
						  WHEN ((select id from MeGusta mg WHERE mg.Id_Usuario = @ID_USUARIO AND mg.Id_Opinion = o.Id) IS NULL)
							 THEN 0
						  ELSE 1
					 END AS bit)
					 AS 'Like',
					 (select COUNT(distinct mg.Id_Usuario) from MeGusta mg where mg.Id_Opinion = o.Id) AS 'Numero_Likes'
					FROM Opinion o inner join Usuario u ON (u.Id = o.Id_Autor) inner join Emoticono e on (e.Id = o.Emoticono)
					WHERE o.Eliminado = 0 AND 
							u.Eliminado = 0 AND
							(O.Titulo LIKE   '%' +@PALABRA + '%' OR
								O.Descripcion LIKE   '%' +@PALABRA + '%')

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
						SET @MENSAJE = 'Opinion no encontrada'
						SET @JSON_OUT = '{"Exito":false}'
					END
			
			END	

	END TRY
	BEGIN CATCH
		SET @MENSAJE = SUBSTRING(ERROR_MESSAGE(), 1, 8000)
		SET @RETCODE = -1
		SET @JSON_OUT = '{"Exito":false}'
	END CATCH
