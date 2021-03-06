USE [MeetFever]
GO
/****** Object:  StoredProcedure [dbo].[PA_Insertar_Registro_De_Error]    Script Date: 15/06/2022 11:10:44 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- ============================================
-- Author: Julio Landazuri Diaz
-- Create date: 23/04/2022
-- Descrption:	Este PA inserta los registros que le llegan.
-- ============================================

	ALTER PROCEDURE [dbo].[PA_Insertar_Registro_De_Error]
	
		@JSON_IN NVARCHAR(MAX), 
		@JSON_OUT NVARCHAR(MAX) OUTPUT,
		@INVOKER INT,
		@RETCODE INT OUTPUT,
		@MENSAJE NVARCHAR(MAX) OUTPUT

	AS
		SET @RETCODE = 0
		SET @MENSAJE = 'Registro insertado.'
		DECLARE @EXCEPCION NVARCHAR(MAX)
		DECLARE @APLICACION_FUENTE INT

	BEGIN TRY

		SELECT @EXCEPCION = Excepcion, @APLICACION_FUENTE = Aplicacion_Fuente
			FROM
				OPENJSON (@JSON_IN) WITH (Excepcion NVARCHAR(MAX), Aplicacion_Fuente INT)
	
		-- Verificaciones de datos de entrada.
		
		IF (@EXCEPCION IS NULL OR @EXCEPCION = '')
			BEGIN
				SET @RETCODE = 1
				SET @MENSAJE = 'Excepcion erronea.'
				SET @JSON_OUT = '{"Exito":false}'
			END

		IF (@APLICACION_FUENTE IS NULL OR @APLICACION_FUENTE = '' OR @APLICACION_FUENTE <0)
			BEGIN
				SET @RETCODE = 2
				SET @MENSAJE = 'ID erroneo.'
				SET @JSON_OUT = '{"Exito":false}'
			END

		SET NOCOUNT ON;
		IF(@RETCODE = 0)
			BEGIN
				INSERT INTO Registro VALUES(@EXCEPCION, @APLICACION_FUENTE)
				SET @JSON_OUT = '{"Exito":true}'
			END
		

	END TRY
	BEGIN CATCH
		SET @MENSAJE = SUBSTRING(ERROR_MESSAGE(), 1, 8000)
		SET @RETCODE = -1
		SET @JSON_OUT = '{"Exito":false}'
	END CATCH
