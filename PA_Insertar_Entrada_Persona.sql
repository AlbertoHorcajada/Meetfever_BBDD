USE [MeetFever]
GO
/****** Object:  StoredProcedure [dbo].[PA_Insertar_Entrada_Persona]    Script Date: 15/06/2022 11:09:43 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- ============================================
-- Author: Alberto Horcajada
-- Create date: 24/04/2022
-- Descrption: Este es un procedimiento almacenado Inserta una Entrada_Persona (venta de una entrada a la experiencia)
-- ============================================

	ALTER PROCEDURE [dbo].[PA_Insertar_Entrada_Persona]
	
		@JSON_IN NVARCHAR(MAX),
		@JSON_OUT NVARCHAR(MAX) OUTPUT,
		@INVOKER INT,
		@RETCODE INT OUTPUT,
		@MENSAJE NVARCHAR(MAX) OUTPUT

	AS
		SET @RETCODE = 0
		SET @MENSAJE = 'Experiencia comprada'


		DECLARE @ID_PERSONA INT
		DECLARE @ID_EXPERIENCIA INT
		DECLARE @FECHA DATETIME
		DECLARE @NOMBRE VARCHAR(50)
		DECLARE @APELLIDO1 VARCHAR(50)
		DECLARE @APELLIDO2 VARCHAR(50)
		DECLARE @DNI CHAR(9)
		DECLARE @Id_paypal NVARCHAR(MAX)


		DECLARE @JSON_PRUEBA NVARCHAR(MAX)
		-- Recuperacion de los datos del JSON entrante
	BEGIN TRY

		SELECT @ID_PERSONA = Id_Persona, 
			@ID_EXPERIENCIA = Id_Experiencia, 
			@FECHA = Fecha, 
			@NOMBRE = Nombre, 
			@APELLIDO1 = Apellido1,
			@APELLIDO2 = Apellido2,
			@DNI = Dni,
			@Id_paypal = Id_paypal
			FROM
				OPENJSON (@JSON_IN) 
				WITH (Id_Persona INT '$.Id_Persona',
				Id_Experiencia INT '$.Id_Experiencia',
				Fecha DATETIME '$.Fecha',
				Nombre VARCHAR(50) '$.Nombre',
				Apellido1 VARCHAR(50) '$.Apellido1',
				Apellido2 VARCHAR(50) '$.Apellido2',
				Dni CHAR(9) '$.Dni',
				Id_paypal NVARCHAR(MAX) '$.Id_Paypal')



		-- Comprobaciones de que los campos obligatorios tienen informacion

		if(@ID_PERSONA IS NULL)
			BEGIN
				SET @RETCODE = 1
				SET @MENSAJE =  'Persona vacia'
				SET @JSON_OUT = '{"Exito":false}'
			END

		ELSE IF (@ID_EXPERIENCIA IS NULL)
			BEGIN
				SET @RETCODE = 2
				SET @RETCODE = 'Experiencia vacia'
				SET @JSON_OUT = '{"Exito":false}'
			END

		ELSE IF(@FECHA IS NULL)
			BEGIN
				SET @RETCODE = 3
				SET @MENSAJE = 'Fecha de venta vacia' 
				SET @JSON_OUT = '{"Exito":false}'
			END

		ELSE IF(@NOMBRE IS NULL or @NOMBRE = '')
			BEGIN
				SET @RETCODE = 4
				SET @MENSAJE = 'Nombre vacio' 
				SET @JSON_OUT = '{"Exito":false}'
			END

		ELSE IF(@APELLIDO1 IS NULL or @APELLIDO1 = '')
			BEGIN
				SET @RETCODE = 5
				SET @MENSAJE = 'Apellido 1 vacio' 
				SET @JSON_OUT = '{"Exito":false}'
			END
			
		ELSE IF(@DNI IS NULL OR @DNI = '')
			BEGIN
				SET @RETCODE = 6
				SET @MENSAJE = 'Dni vacio'
				SET @JSON_OUT = '{"Exito":false}'
			END

		ELSE IF(@Id_paypal IS NULL OR @Id_paypal = '')
			BEGIN
				SET @RETCODE = 6
				SET @MENSAJE = 'Id Paypal vacio'
				SET @JSON_OUT = '{"Exito":false}'
			END
			
		IF(@RETCODE = 0)
			BEGIN
				SET @JSON_PRUEBA = (
				SELECT 
				p.Id
				FROM Persona p
				where p.Id = @ID_PERSONA and p.Eliminado = 0
				FOR JSON PATH)

				If (@JSON_PRUEBA is null or @JSON_PRUEBA = '')
					BEGIN
						SET @RETCODE = 7
						SET @MENSAJE = 'Persona no existente o eliminada logicamente'
						SET @JSON_OUT = '{"Exito":false}'
					END
				ELSE
					BEGIN
						SET @JSON_PRUEBA = NULL
						SET @JSON_PRUEBA = (
							SELECT 
							e.Id
							FROM Experiencia e
							where e.Id = @ID_EXPERIENCIA and e.Eliminado = 0
							FOR JSON PATH)
					END
					
					IF(@JSON_PRUEBA is null or @JSON_PRUEBA = '')
						BEGIN
							SET @RETCODE = 8
							SET @MENSAJE = 'Experiencia no existente o eliminada logicamente'
							SET @JSON_OUT = '{"Exito":false}'
						END
					ELSE
						BEGIN
							SET @JSON_PRUEBA = NULL
							SET @JSON_PRUEBA = (
								SELECT 
								e.Id
								FROM Entrada_Persona e
								where e.Id_Experiencia = @ID_EXPERIENCIA AND
									e.Fecha = @FECHA AND
									e.Dni = @DNI AND
									e.Eliminado = 0
								FOR JSON PATH)

								/*IF(@JSON_PRUEBA IS NOT NULL)
									BEGIN
										SET @RETCODE = 9
										SET @MENSAJE = 'Entrada ya comprada para esta experiencia y fecha a Dni de la misma persona'
										SET @JSON_OUT = '{"Exito":false}'
									END*/
						END
			
		
			END

		SET NOCOUNT ON;

		if (@RETCODE = 0)
			BEGIN

				insert into Entrada_Persona
					(
					Id_Persona,
					Id_Experiencia,
					Fecha,
					Nombre,
					Apellido1,
					Apellido2,
					Dni,
					Eliminado,
					Id_paypal
					) 
				values 
					(
					@ID_PERSONA,
					@ID_EXPERIENCIA,
					@FECHA,
					@NOMBRE,
					@APELLIDO1,
					@APELLIDO2,
					@DNI,
					0,
					@Id_paypal
					)
			
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
		