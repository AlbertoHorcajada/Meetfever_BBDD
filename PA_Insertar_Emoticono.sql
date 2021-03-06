USE [MeetFever]
GO
/****** Object:  StoredProcedure [dbo].[PA_Insertar_Emoticono]    Script Date: 15/06/2022 11:09:16 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- ============================================
-- Author: Alberto Horcajada
-- Create date: 24/04/2022
-- Descrption: Este es un procedimiento almacenado Inserta un Emoticono
-- ============================================

	ALTER PROCEDURE [dbo].[PA_Insertar_Emoticono]
	
		@JSON_IN NVARCHAR(MAX), 
		@JSON_OUT NVARCHAR(MAX) OUTPUT,
		@INVOKER INT,
		@RETCODE INT OUTPUT,
		@MENSAJE NVARCHAR(MAX) OUTPUT

	AS
		SET @RETCODE = 0
		SET @MENSAJE = 'Emoticono insertado'


		DECLARE @EMOTICONO NVARCHAR(MAX)

		


		DECLARE @JSON_PRUEBA NVARCHAR(MAX)
		DECLARE @ELIMINADO BIT
		-- Recuperacion de los datos del JSON entrante
	BEGIN TRY

		SELECT @EMOTICONO = Emoji 
			
			FROM
				OPENJSON (@JSON_IN) 
				WITH (Emoji NVARCHAR(MAX) '$.Emoji')



		-- Comprobaciones de que los campos obligatorios tienen informacion

		if(@EMOTICONO IS NULL or @EMOTICONO = '')
			BEGIN
				SET @RETCODE = 1
				SET @MENSAJE =  'Emoticono vacio'
				SET @JSON_OUT = '{"Exito":false}'
			END

		IF(@RETCODE = 0)
		BEGIN
			SET @JSON_PRUEBA = (
			SELECT 
			e.Emoji
			FROM Emoticono e
			where e.Emoji = @EMOTICONO
			FOR JSON PATH)

			If (@JSON_PRUEBA is not null or @JSON_PRUEBA != '')
				BEGIN
					SET @RETCODE = 2
					SET @MENSAJE = 'Emoticono existente'
					SET @JSON_OUT = '{"Exito":false}'
				END
		END
		
		
		

		SET NOCOUNT ON;

		if (@RETCODE = 0)
			BEGIN

			insert into Emoticono
				(Emoji,
				Eliminado)
				
			values
				(@EMOTICONO,
				0)

				SET @JSON_OUT = '{"Exito":true}'

			END
		ELSE
			BEGIN
				SET @JSON_OUT = '{"Exito":false}'
			END
		
		

		

	END TRY
	BEGIN CATCH
		SET @MENSAJE = SUBSTRING(ERROR_MESSAGE(), 1, 8000)
		SET @RETCODE = -1
		SET @JSON_OUT = '{"Exito":false}'
	END CATCH
		