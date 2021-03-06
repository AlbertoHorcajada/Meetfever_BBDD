USE [MeetFever]
GO
/****** Object:  StoredProcedure [dbo].[PA_Actualizar_Emoticono]    Script Date: 15/06/2022 11:01:46 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- ============================================
-- Author: Alberto Horcajada
-- Create date: 24/04/2022
-- Descrption: Este es un procedimiento almacenado Actualizar un Emoticono
-- ============================================

	ALTER PROCEDURE [dbo].[PA_Actualizar_Emoticono]
	
		@JSON_IN NVARCHAR(MAX), 
		@JSON_OUT NVARCHAR(MAX) OUTPUT,
		@INVOKER INT,
		@RETCODE INT OUTPUT,
		@MENSAJE NVARCHAR(MAX) OUTPUT

	AS
		SET @RETCODE = 0
		SET @MENSAJE = 'Emoticono actualizado'


		DECLARE @EMOTICONO NVARCHAR(MAX)
		DECLARE @ID INT
		


		DECLARE @JSON_PRUEBA NVARCHAR(MAX)
		

		-- Recuperacion de los datos del JSON entrante
	BEGIN TRY

		BEGIN TRANSACTION

			SELECT @EMOTICONO = Emoji , @ID = Id
			
				FROM
					OPENJSON (@JSON_IN) 
					WITH (Emoji NVARCHAR(MAX) '$.Emoji', Id INT '$.Id')



			-- Comprobaciones de que los campos obligatorios tienen informacion

			if(@EMOTICONO IS NULL or @EMOTICONO = '')
				BEGIN
					SET @RETCODE = 1
					SET @MENSAJE =  'Emoticono vacio'
					SET @JSON_OUT = '{"Exito":false}'
				END


			-- Comrpobaciones de que las claves foraneas existen

				-- Comprobar que existe la empresa
			IF(@RETCODE = 0)
			BEGIN
				SET @JSON_PRUEBA = (
				SELECT 
				e.Id
				FROM Emoticono e
				where e.Id = @ID AND Eliminado = 0
				FOR JSON PATH)
			


				If (@JSON_PRUEBA is null or @JSON_PRUEBA = '')
					BEGIN
						SET @RETCODE = 2
						SET @MENSAJE = 'Emoticono inexistente o eliminado de forma logica'
						SET @JSON_OUT = '{"Exito":false}'
					END
			END
		
		
		

			SET NOCOUNT ON;

			-- Buscar en la BBDD el Usuario por ID y crear el JSON
			if (@RETCODE = 0)
				BEGIN

				update Emoticono
					set Emoji = @EMOTICONO
						WHERE Id = @ID

				SET @JSON_OUT = '{"Exito":true}'
			
				END
		
		COMMIT TRANSACTION

		

	END TRY
	BEGIN CATCH
		SET @MENSAJE = SUBSTRING(ERROR_MESSAGE(), 1, 8000)
		SET @RETCODE = -1
		SET @JSON_OUT = '{"Exito":false}'
		ROLLBACK TRANSACTION
	END CATCH
		