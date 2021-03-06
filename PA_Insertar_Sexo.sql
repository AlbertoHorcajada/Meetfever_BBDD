USE [MeetFever]
GO
/****** Object:  StoredProcedure [dbo].[PA_Insertar_Sexo]    Script Date: 15/06/2022 11:10:51 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- ============================================
-- Author: Alberto Horcajada
-- Create date: 24/04/2022
-- Descrption: Este es un procedimiento almacenado Inserta un Sexo
-- ============================================

	ALTER PROCEDURE [dbo].[PA_Insertar_Sexo]
	
		@JSON_IN NVARCHAR(MAX), 
		@JSON_OUT NVARCHAR(MAX) OUTPUT,
		@INVOKER INT,
		@RETCODE INT OUTPUT,
		@MENSAJE NVARCHAR(MAX) OUTPUT

	AS
		SET @RETCODE = 0
		SET @MENSAJE = 'Sexo insertado'


		DECLARE @SEXO VARCHAR(40)

		


		DECLARE @JSON_PRUEBA NVARCHAR(MAX)
		DECLARE @ELIMINADO BIT
		-- Recuperacion de los datos del JSON entrante
	BEGIN TRY

		SELECT @SEXO = Sexo 
			
			FROM
				OPENJSON (@JSON_IN) 
				WITH (Sexo VARCHAR(40) '$.Sexo')



		-- Comprobaciones de que los campos obligatorios tienen informacion

		if(@SEXO IS NULL or @SEXO = '')
			BEGIN
				SET @RETCODE = 1
				SET @MENSAJE =  'Sexo vacio'
				SET @JSON_OUT = '{"Exito":false}'
			END


	
		IF(@RETCODE = 0)
		BEGIN
			SET @JSON_PRUEBA = (
			SELECT 
			s.Sexo
			FROM Sexo s
			where s.Sexo = @SEXO
			FOR JSON PATH)

			If (@JSON_PRUEBA is not null or @JSON_PRUEBA != '')
				BEGIN
					SET @RETCODE = 2
					SET @MENSAJE = 'Sexo existente'
					SET @JSON_OUT = '{"Exito":false}'
				END
		END
		
		
		

		SET NOCOUNT ON;

		if (@RETCODE = 0)
			BEGIN

			insert into Sexo
				(Sexo,
				Eliminado) 
			values
				(@SEXO,
				0)

				SET @JSON_OUT = '{"Exito":True}'

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
		