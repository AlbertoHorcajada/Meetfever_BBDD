USE [MeetFever]
GO
/****** Object:  StoredProcedure [dbo].[PA_Obtener_Todos_Emoticonos]    Script Date: 15/06/2022 11:19:22 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- ============================================
-- Author: Alberto Horcajada
-- Create date: 24/04/2022
-- Descrption: Este es un procedimiento almacenado que devuelve todos los datos de todos los Emoticonos que no hayan sido borrados de forma logica
-- ============================================

	ALTER PROCEDURE [dbo].[PA_Obtener_Todos_Emoticonos]
	
		@JSON_OUT NVARCHAR(MAX) OUTPUT,
		@INVOKER INT,
		@RETCODE INT OUTPUT,
		@MENSAJE NVARCHAR(MAX) OUTPUT

	AS
		SET @RETCODE = 0
		SET @MENSAJE = 'Emoticonos devueltos'


		-- Recuperacion del ID del JSON entrante
	BEGIN TRY

		SET NOCOUNT ON;

		-- Crear JSON de respuesta a raiz de la consulta

		SET @JSON_OUT = (
			
			SELECT e.Id, e.Emoji
			FROM Emoticono e
			WHERE e.Eliminado = 0
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
				SET @MENSAJE = 'emoticonos no encontrados'
				SET @JSON_OUT = '{"Exito":false}'
			END
		

		

		

	END TRY
	BEGIN CATCH
		SET @MENSAJE = SUBSTRING(ERROR_MESSAGE(), 1, 8000)
		SET @RETCODE = -1
		SET @JSON_OUT = '{"Exito":false}'
	END CATCH
