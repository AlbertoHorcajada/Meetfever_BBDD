USE [MeetFever]
GO
/****** Object:  StoredProcedure [dbo].[PA_Obtener_Opinion_Por_ID]    Script Date: 15/06/2022 11:13:57 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- ============================================
-- Author: Alberto Horcajada
-- Create date: 24/04/2022
-- Descrption: Este es un procedimiento almacenado que devuelve todos los datos de una opinion por una ID
-- ============================================

	ALTER PROCEDURE [dbo].[PA_Obtener_Opinion_Por_ID]
	
		@JSON_IN NVARCHAR(MAX), 
		@JSON_OUT NVARCHAR(MAX) OUTPUT,
		@INVOKER INT,
		@RETCODE INT OUTPUT,
		@MENSAJE NVARCHAR(MAX) OUTPUT

	AS
		SET @RETCODE = 0
		SET @MENSAJE = 'Opinion encontrada exitosamente'
		DECLARE @ID INT
		DECLARE @ID_USUARIO	INT

		DECLARE @JSON_ELIMINADO NVARCHAR(MAX)
		DECLARE @ELIMINADO BIT
		-- Recuperacion del ID del JSON entrante
	BEGIN TRY

		SELECT @ID = Id, @ID_USUARIO = Id_Usuario
			FROM
				OPENJSON (@JSON_IN) WITH (Id INT '$.Id', Id_Usuario INT '$.Id_Usuario')
		-- Comrpobaciones de ese ID
		
		IF (@ID IS NULL)
			BEGIN
				SET @RETCODE = 1
				SET @MENSAJE = 'ID nulo'
				SET @JSON_OUT = '{"Exito":false}'
			END

		IF (@ID = '')
			BEGIN
				SET @RETCODE = 2
				SET @MENSAJE = 'ID vacio'
				SET @JSON_OUT = '{"Exito":false}'
			END

		IF (@ID <0)
			BEGIN
				SET @RETCODE = 3
				SET @MENSAJE = 'ID menor que 0'
				SET @JSON_OUT = '{"Exito":false}'
			END

		IF (@ID_USUARIO IS NULL)
			BEGIN
				SET @RETCODE = 4
				SET @MENSAJE = 'Id_Usuario nulo'
				SET @JSON_OUT = '{"Exito":false}'
			END

		SET NOCOUNT ON;

		-- Crear JSON de respuesta a raiz de la consulta

		SET @JSON_OUT = (
			
			SELECT o.Id,
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
			WHERE o.id = @ID
			FOR JSON PATH, WITHOUT_ARRAY_WRAPPER)


		-- Dos comprobaciones para asegurarnos de que está bien el JSON

		IF (@JSON_OUT = '')
			BEGIN
				SET @RETCODE = 5
				SET @MENSAJE = 'JSON vacio'
			END


		IF(@JSON_OUT IS NULL)
			BEGIN
				SET @RETCODE = 6
				SET @MENSAJE = 'Opinion no encontrada'
			END
		ELSE
			BEGIN
				SET @JSON_ELIMINADO = (
					SELECT o.Eliminado
					FROM Opinion o
					WHERE id = @ID
				FOR JSON AUTO)

				SELECT @ELIMINADO = Eliminado
					FROM
						OPENJSON (@JSON_ELIMINADO) WITH (Eliminado BIT '$.Eliminado')

				IF (@ELIMINADO = 1)
					BEGIN	

						SET @JSON_OUT = null
						SET @RETCODE = 6
						SET @MENSAJE = 'Opinion eliminada de forma logica'

					END

			END	

		

		

	END TRY
	BEGIN CATCH
		SET @MENSAJE = SUBSTRING(ERROR_MESSAGE(), 1, 8000)
		SET @RETCODE = -1
	END CATCH
