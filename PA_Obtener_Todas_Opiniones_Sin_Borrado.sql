USE [MeetFever]
GO
/****** Object:  StoredProcedure [dbo].[PA_Obtener_Todas_Opiniones_Sin_Borrado]    Script Date: 07/06/2022 21:24:38 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- ============================================
-- Author: Alberto Horcajada
-- Create date: 24/04/2022
-- Descrption: Este es un procedimiento almacenado que devuelve todos los datos de todas las opiniones
-- ============================================

	ALTER PROCEDURE [dbo].[PA_Obtener_Todas_Opiniones_Sin_Borrado]
	
		@JSON_OUT NVARCHAR(MAX) OUTPUT,
		@INVOKER INT,
		@RETCODE INT OUTPUT,
		@MENSAJE NVARCHAR(MAX) OUTPUT

	AS
		SET @RETCODE = 0
		SET @MENSAJE = 'opiniones devueltas'


		

		-- Recuperacion del ID del JSON entrante
	BEGIN TRY

		SET NOCOUNT ON;
	
		
		-- Crear JSON de respuesta a raiz de la consulta

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
			o.Eliminado
			FROM Opinion o INNER JOIN Usuario u  ON (U.Id = o.Id_Autor)
				INNER JOIN Emoticono e ON (e.Id = o.Emoticono)
			FOR JSON PATH)


		-- Dos comprobaciones para asegurarnos de que está bien el JSON

		IF (@JSON_OUT = '')
			BEGIN
				SET @RETCODE = 1
				SET @MENSAJE = 'JSON vacio'
				SET @JSON_OUT = '{"Exito":false}'
			END


		IF(@JSON_OUT IS NULL)
			BEGIN
				SET @RETCODE = 2
				SET @MENSAJE = 'opiniones no encontradas'
				SET @JSON_OUT = '{"Exito":false}'
			END
		

		

		

	END TRY
	BEGIN CATCH
		SET @MENSAJE = SUBSTRING(ERROR_MESSAGE(), 1, 8000)
		SET @RETCODE = -1
		SET @JSON_OUT = '{"Exito":false}'
	END CATCH
