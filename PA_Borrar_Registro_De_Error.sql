USE [MeetFever]
GO
/****** Object:  StoredProcedure [dbo].[PA_Borrar_Registro_De_Error]    Script Date: 15/06/2022 11:08:19 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- ============================================
-- Author: Julio Landazuri Diaz
-- Create date: 23/04/2022
-- Descrption:	Este PA Elimina un registro de error por un ID.
-- ============================================

	ALTER PROCEDURE [dbo].[PA_Borrar_Registro_De_Error]
	
		@JSON_IN NVARCHAR(MAX), 
		@JSON_OUT NVARCHAR(MAX) OUTPUT,
		@INVOKER INT,
		@RETCODE INT OUTPUT,
		@MENSAJE NVARCHAR(MAX) OUTPUT

	AS
		SET @RETCODE = 0
		SET @MENSAJE = 'Registro eliminado'
		DECLARE @ID INT


	BEGIN TRY

		SELECT @ID = Id
			FROM
				OPENJSON (@JSON_IN) WITH (Id INT '$.Id')
	
		-- Verificaciones de datos de entrada.
		
		IF (@ID IS NULL OR @ID = '')
			BEGIN
				SET @RETCODE = 1
				SET @MENSAJE = 'ID erroneo.'
				SET @JSON_OUT = '{"Exito":false}'
			END

		SET NOCOUNT ON;
		IF(@RETCODE = 0)
			BEGIN
				DELETE FROM  Registro WHERE Id = @ID
				SET @JSON_OUT = '{"Exito":true}'
			END
		

	END TRY
	BEGIN CATCH
		SET @MENSAJE = SUBSTRING(ERROR_MESSAGE(), 1, 8000)
		SET @RETCODE = -1
		SET @JSON_OUT = '{"Exito":false}'
	END CATCH
