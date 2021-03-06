USE [MeetFever]
GO
/****** Object:  StoredProcedure [dbo].[PA_Actualizar_Sexo]    Script Date: 15/06/2022 11:05:37 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- ============================================
-- Author: Alberto Horcajada
-- Create date: 24/04/2022
-- Descrption: Este es un procedimiento almacenado Actualiza un Sexo
-- ============================================

	ALTER PROCEDURE [dbo].[PA_Actualizar_Sexo]
	
		@JSON_IN NVARCHAR(MAX), 
		@JSON_OUT NVARCHAR(MAX) OUTPUT,
		@INVOKER INT,
		@RETCODE INT OUTPUT,
		@MENSAJE NVARCHAR(MAX) OUTPUT

	AS
		SET @RETCODE = 0
		SET @MENSAJE = 'Sexo actualizado'

		DECLARE @ID INT
		DECLARE @SEXO VARCHAR(40)

		


		DECLARE @JSON_PRUEBA NVARCHAR(MAX)
		DECLARE @ELIMINADO BIT
	BEGIN TRY

		BEGIN TRANSACTION

			SELECT @SEXO = Sexo , @ID = Id
			
				FROM
					OPENJSON (@JSON_IN) 
					WITH (Sexo VARCHAR(40) '$.Sexo', Id INT '$.Id')




			if(@SEXO IS NULL or @SEXO = '')
				BEGIN
					SET @RETCODE = 1
					SET @MENSAJE =  'Sexo vacio'
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
				s.Sexo
				FROM Sexo s
				where s.Id = @ID AND s.Eliminado = 0
				FOR JSON PATH)

				If (@JSON_PRUEBA is null or @JSON_PRUEBA = '')
					BEGIN
						SET @RETCODE = 3
						SET @MENSAJE = 'Sexo inexistente o eliminado de forma logica'
						SET @JSON_OUT = '{"Exito":false}'
					END
			END
		
		
		

			SET NOCOUNT ON;

			if (@RETCODE = 0)
				BEGIN

				UPDATE Sexo
					set Sexo = @SEXO
						where id = @ID

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
		