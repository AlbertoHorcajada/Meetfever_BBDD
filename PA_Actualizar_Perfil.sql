USE [MeetFever]
GO
/****** Object:  StoredProcedure [dbo].[PA_Actualizar_Perfil]    Script Date: 15/06/2022 11:05:26 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- ============================================
-- Author: Alberto Horcajada
-- Create date: 24/04/2022
-- Descrption: Este es un procedimiento almacenado Actualiza un Perfil
-- ============================================

	ALTER PROCEDURE [dbo].[PA_Actualizar_Perfil]
	
		@JSON_IN NVARCHAR(MAX), 
		@JSON_OUT NVARCHAR(MAX) OUTPUT,
		@INVOKER INT,
		@RETCODE INT OUTPUT,
		@MENSAJE NVARCHAR(MAX) OUTPUT

	AS
		SET @RETCODE = 0
		SET @MENSAJE = 'Perfil Actualizado'

		DECLARE @ID INT
		DECLARE @CARGO VARCHAR(40)

		


		DECLARE @JSON_PRUEBA NVARCHAR(MAX)
		DECLARE @ELIMINADO BIT
	BEGIN TRY

		BEGIN TRANSACTION

			SELECT @CARGO = Cargo , @ID = Id
			
				FROM
					OPENJSON (@JSON_IN) 
					WITH (cargo VARCHAR(40) '$.Cargo', id INT '$.Id')




			if(@CARGO IS NULL or @CARGO = '')
				BEGIN
					SET @RETCODE = 1
					SET @MENSAJE =  'Cargo vacio'
					SET @JSON_OUT = '{"Exito":false}'
				END
			ELSE IF (@ID IS NULL)
				BEGIN
					SET @RETCODE = 2
					SET @MENSAJE = 'Id vacio'
					SET @JSON_OUT = '{"Exito":false}'
				END



			IF(@RETCODE = 0)
			BEGIN
				SET @JSON_PRUEBA = (
				SELECT 
				p.Id
				FROM Perfil p
				where p.Id = @ID and Eliminado = 0
				FOR JSON PATH)

				If (@JSON_PRUEBA is null or @JSON_PRUEBA != '')
					BEGIN
						SET @RETCODE = 2
						SET @MENSAJE = 'Cargo inexistente o borrado de forma logica'
						SET @JSON_OUT = '{"Exito":false}'
					END
			END
		
		
		

			SET NOCOUNT ON;

			if (@RETCODE = 0)
				BEGIN

				UPDATE Perfil
					SET Cargo = @CARGO
						WHERE Id = @ID

				SET @JSON_OUT = '{"Exito":true}'
				END
			ELSE
				BEGIN
					SET @JSON_OUT = '{"Exito":false}'
				END
		
		
		COMMIT TRANSACTION
		

	END TRY
	BEGIN CATCH
		SET @MENSAJE = SUBSTRING(ERROR_MESSAGE(), 1, 8000)
		SET @RETCODE = -1
		SET @JSON_OUT = '{"Exito":false}'
		ROLLBACK TRANSACTION
	END CATCH
		