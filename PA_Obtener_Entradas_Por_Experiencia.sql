USE [MeetFever]
GO
/****** Object:  StoredProcedure [dbo].[PA_Obtener_Entradas_Por_Experiencia]    Script Date: 15/06/2022 11:12:23 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- ============================================
-- Author: Alberto Horcajada
-- Create date: 24/04/2022
-- Descrption: Este es un procedimiento almacenado que devuelve todas las entradas compradas de una experiencia
-- ============================================

	ALTER PROCEDURE [dbo].[PA_Obtener_Entradas_Por_Experiencia]
	
		@JSON_IN NVARCHAR(MAX), 
		@JSON_OUT NVARCHAR(MAX) OUTPUT,
		@INVOKER INT,
		@RETCODE INT OUTPUT,
		@MENSAJE NVARCHAR(MAX) OUTPUT

	AS
		SET @RETCODE = 0
		SET @MENSAJE = 'Entradas encontradas'
		DECLARE @ID_EXPERIENCIA INT

		DECLARE @JSONPRUEBA NVARCHAR(MAX)

		-- Recuperacion del ID del JSON entrante
	BEGIN TRY

		SELECT @ID_EXPERIENCIA = Id_Experiencia
			FROM
				OPENJSON (@JSON_IN) WITH (Id_Experiencia INT '$.Id')
		-- Comrpobaciones de ese ID
		
		IF (@ID_EXPERIENCIA IS NULL)
			BEGIN
				SET @RETCODE = 1
				SET @MENSAJE = 'ID nulo'
				SET @JSON_OUT = '{"Exito":false}'
			END

		ELSE IF (@ID_EXPERIENCIA = '')
			BEGIN
				SET @RETCODE = 2
				SET @MENSAJE = 'ID vacio'
				SET @JSON_OUT = '{"Exito":false}'
			END

		ELSE IF (@ID_EXPERIENCIA <0)
			BEGIN
				SET @RETCODE = 3
				SET @MENSAJE = 'ID no valido, numero negativo'
				SET @JSON_OUT = '{"Exito":false}'
			END

		IF (@RETCODE = 0)
			BEGIN
				SET @JSONPRUEBA = (
					SELECT Id
					From Experiencia
					WHERE Id = @ID_EXPERIENCIA AND Eliminado = 0
				)

				IF (@JSONPRUEBA IS NULL)
					BEGIN
						SET @RETCODE = 4
						SET @MENSAJE = 'Experiencia inexistente o borrada de forma logica'
						SET @JSON_OUT = '{"Exito":false}'
					END

			END

		SET NOCOUNT ON;

		-- Crear JSON de respuesta a raiz de la consulta
	IF (@RETCODE = 0)
	BEGIN
		SET @JSON_OUT = (
			
			SELECT DISTINCT
			
			COUNT(e.Id) AS 'Entradas_Vendidas'
			FROM Entrada_Persona e
			WHERE e.Id_Experiencia = @ID_EXPERIENCIA and e.eliminado = 0
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
