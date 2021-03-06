USE [MeetFever]
GO
/****** Object:  StoredProcedure [dbo].[PA_Actualizar_Empresa]    Script Date: 15/06/2022 11:04:55 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- ============================================
-- Author: Alberto Horcajada
-- Create date: 24/04/2022
-- Descrption: Este es un procedimiento almacenado Actualiza una empresa
-- ============================================

	ALTER PROCEDURE [dbo].[PA_Actualizar_Empresa]
	
		@JSON_IN NVARCHAR(MAX), 
		@INVOKER INT,
		@JSON_OUT NVARCHAR(MAX) OUTPUT,
		@RETCODE INT OUTPUT,
		@MENSAJE NVARCHAR(MAX) OUTPUT

	AS
		SET @RETCODE = 0
		SET @MENSAJE = 'Empresa actualizada'

		DECLARE @ID INT
		DECLARE @CORREO VARCHAR(255)
		DECLARE @CONTRASENA VARCHAR(255)
		DECLARE @NICK VARCHAR(30)
		DECLARE @FOTO_FONDO NVARCHAR(MAX)
		DECLARE @FOTO_PERFIL NVARCHAR(MAX)
		DECLARE @TELEFONO CHAR(9)
		DECLARE @FRASE VARCHAR(255)
		DECLARE @NOMBRE_EMPRESA VARCHAR(100)
		DECLARE @CIF CHAR(9)
		DECLARE @DIRECCION_FACTURACION VARCHAR(100)
		DECLARE @DIRECCION_FISCAL VARCHAR(100)
		DECLARE @NOMBRE_PERSONA VARCHAR(50)
		DECLARE @APELLIDO1_PERSONA VARCHAR(50)
		DECLARE @APELLIDO2_PERSONA VARCHAR(50)
		DECLARE @DNI_PERSONA CHAR(9)


		DECLARE @JSON_PRUEBA NVARCHAR(MAX)
	BEGIN TRY

		BEGIN TRANSACTION

			SELECT @ID = Id,
				@CORREO = Correo, 
				@CONTRASENA = Contrasena, 
				@NICK = Nick, 
				@FOTO_FONDO = Foto_Fondo, 
				@FOTO_PERFIL = Foto_Perfil,
				@TELEFONO = Telefono,
				@FRASE = Frase,
				@NOMBRE_EMPRESA = Nombre_Empresa,
				@CIF = Cif,
				@DIRECCION_FACTURACION = Direccion_Facturacion,
				@DIRECCION_FISCAL = Direccion_Fiscal,
				@NOMBRE_PERSONA = Nombre_Persona,
				@APELLIDO1_PERSONA = Apellido1_Persona,
				@APELLIDO2_PERSONA = Apellido2_Persona,
				@DNI_PERSONA = Dni_Persona
				FROM
					OPENJSON (@JSON_IN) 
					WITH (Id INT '$.Id',
					Correo VARCHAR(255) '$.Correo',
					Contrasena VARCHAR(255) '$.Contrasena',
					Nick VARCHAR(30) '$.Nick',
					Foto_Fondo NVARCHAR(MAX) '$.Foto_Fondo',
					Foto_Perfil NVARCHAR(MAX)'$.Foto_Perfil',
					Telefono CHAR(9) '$.Telefono',
					Frase VARCHAR(255)'$.Frase',
					Nombre_Empresa VARCHAR(100) '$.Nombre_Empresa',
					Cif CHAR(9) '$.Cif',
					Direccion_Facturacion VARCHAR(100) '$.Direccion_Facturacion',
					Direccion_Fiscal VARCHAR(100) '$.Direccion_Fiscal',
					Nombre_Persona VARCHAR(50) '$.Nombre_Persona',
					Apellido1_Persona VARCHAR(50) '$.Apellido1_Persona',
					Apellido2_Persona VARCHAR(50) '$.Apellido2_Persona',
					Dni_Persona CHAR(9) '$.Dni_Persona')


			if(@CORREO IS NULL or @CORREO = '')
				BEGIN
					SET @RETCODE = 1
					SET @MENSAJE =  'Correo vacio'
					SET @JSON_OUT = '{"Exito":false}'
				END

			ELSE IF (@CONTRASENA IS NULL OR @CONTRASENA = '')
				BEGIN
					SET @RETCODE = 2
					SET @RETCODE = 'Contraseña vacia'
					SET @JSON_OUT = '{"Exito":false}'
				END

			ELSE IF(@NICK IS NULL OR @NICK = '')
				BEGIN
					SET @RETCODE = 3
					SET @MENSAJE = 'Nick vacio' 
					SET @JSON_OUT = '{"Exito":false}'
				END
			ELSE IF (@ID IS NULL)
				BEGIN
					SET @RETCODE = 4
					SET @MENSAJE = 'Id vacio'
					SET @JSON_OUT = '{"Exito":false}'
				END

			IF(@RETCODE = 0)
			BEGIN
				SET @JSON_PRUEBA = (
				SELECT 
				u.id
				FROM Usuario u
				where U.Correo = @CORREO AND u.Id != @ID
				FOR JSON PATH)

				If (@JSON_PRUEBA is not null or @JSON_PRUEBA != '')
					BEGIN
						SET @RETCODE = 5
						SET @MENSAJE = 'Correo ya existente'
						SET @JSON_OUT = '{"Exito":false}'
					END
				ELSE
					BEGIN

					SET @JSON_PRUEBA = (
						SELECT 
						u.Nick
						FROM Usuario u
						where U.Nick = @NICK AND U.id != @ID
					FOR JSON PATH)

					IF (@JSON_PRUEBA is not null or @JSON_PRUEBA != '')
						BEGIN
							SET @RETCODE = 6
							SET @MENSAJE = 'Nick ya existente'
							SET @JSON_OUT = '{"Exito":false}'
						END
					ELSE
						BEGIN

						SET @JSON_PRUEBA = (
							SELECT 
							e.Nombre_Empresa
							FROM Empresa e
							where e.Nombre_Empresa = @NOMBRE_EMPRESA AND e.Id != @ID
						FOR JSON PATH)

						IF (@JSON_PRUEBA is not null or @JSON_PRUEBA != '')
							BEGIN
								SET @RETCODE = 7
								SET @MENSAJE = 'Empresa ya existente'
								SET @JSON_OUT = '{"Exito":false}'
							END
						ELSE
							BEGIN

							SET @JSON_PRUEBA = (
								SELECT 
								e.Cif
								FROM Empresa e
								WHERE e.Cif = @CIF AND e.Id !=@ID
							FOR JSON PATH)

							IF (@JSON_PRUEBA is not null or @JSON_PRUEBA != '')
								BEGIN
									SET @RETCODE = 8
									SET @MENSAJE = 'Cif ya existente'
									SET @JSON_OUT = '{"Exito":false}'
								END

							END

						END

					END
			END		
		
			IF (@RETCODE = 0)
				BEGIN
					SET @JSON_PRUEBA = NULL

					SET @JSON_PRUEBA = (
						SELECT e.Id
							FROM Empresa e
								WHERE e.Id = @ID AND e.Eliminado = 0
					FOR JSON AUTO)

					IF (@JSON_PRUEBA IS NULL)
						BEGIN
							SET @RETCODE = 9
							SET @MENSAJE = 'No existe la empresa o borrada de forma logica'
							SET @JSON_OUT = '{"Exito":false}'
						END

				END
		

			SET NOCOUNT ON;


			if (@RETCODE = 0)
				BEGIN

				UPDATE Usuario
					SET
						Correo = @CORREO,
						Contrasena = @CONTRASENA,
						Nick = @NICK,
						Foto_Perfil = @FOTO_PERFIL,
						Foto_Fondo = @FOTO_FONDO,
						Telefono = @TELEFONO,
						Frase = @FRASE
					WHERE Id = @ID

				UPDATE Empresa
					SET	
						Nombre_Empresa = @NOMBRE_EMPRESA,
						Cif = @CIF,
						Direccion_Facturacion = @DIRECCION_FACTURACION,
						Direccion_Fiscal = @DIRECCION_FISCAL,
						Nombre_Persona = @NOMBRE_PERSONA,
						Apellido1_Persona = @APELLIDO1_PERSONA,
						Apellido2_Persona = @APELLIDO2_PERSONA,
						Dni_Persona = @DNI_PERSONA

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
		