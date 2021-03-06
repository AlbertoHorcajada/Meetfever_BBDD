USE [MeetFever]
GO
/****** Object:  StoredProcedure [dbo].[PA_Insertar_Perfil]    Script Date: 15/06/2022 11:10:14 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- ============================================
-- Author: Alberto Horcajada
-- Create date: 24/04/2022
-- Descrption: Este es un procedimiento almacenado Inserta un Perfil
-- ============================================

	ALTER PROCEDURE [dbo].[PA_Insertar_Perfil]
	
		@JSON_IN NVARCHAR(MAX), 
		@JSON_OUT NVARCHAR(MAX) OUTPUT,
		@INVOKER INT,
		@RETCODE INT OUTPUT,
		@MENSAJE NVARCHAR(MAX) OUTPUT

	AS
		SET @RETCODE = 0
		SET @MENSAJE = 'Perfil insertado'


		DECLARE @CARGO VARCHAR(40)

		


		DECLARE @JSON_PRUEBA NVARCHAR(MAX)
		DECLARE @ELIMINADO BIT
		-- Recuperacion de los datos del JSON entrante
	BEGIN TRY

		SELECT @CARGO = Cargo 
			
			FROM
				OPENJSON (@JSON_IN) 
				WITH (Cargo VARCHAR(40) '$.Cargo')



		-- Comprobaciones de que los campos obligatorios tienen informacion

		if(@CARGO IS NULL or @CARGO = '')
			BEGIN
				SET @RETCODE = 1
				SET @MENSAJE =  'Cargo vacio'
				SET @JSON_OUT = '{"Exito":false}'
			END

		IF(@RETCODE = 0)
		BEGIN
			SET @JSON_PRUEBA = (
			SELECT 
			p.Cargo
			FROM Perfil p
			where p.Cargo = @CARGO
			FOR JSON PATH)

			If (@JSON_PRUEBA is not null or @JSON_PRUEBA != '')
				BEGIN
					SET @RETCODE = 2
					SET @MENSAJE = 'Cargo existente'
					SET @JSON_OUT = '{"Exito":false}'
				END
		END
		
		
		

		SET NOCOUNT ON;

		if (@RETCODE = 0)
			BEGIN

			insert into Perfil
				(Cargo,
				Eliminado) 
			values
				(@CARGO,
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
		