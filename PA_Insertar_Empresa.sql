USE [MeetFever]
GO
/****** Object:  StoredProcedure [dbo].[PA_Insertar_Empresa]    Script Date: 15/06/2022 11:09:36 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- ============================================
-- Author: Alberto Horcajada
-- Create date: 24/04/2022
-- Descrption: Este es un procedimiento almacenado Inserta una empresa
-- ============================================

	ALTER PROCEDURE [dbo].[PA_Insertar_Empresa]
	
		@JSON_IN NVARCHAR(MAX), 
		@JSON_OUT NVARCHAR(MAX) OUTPUT,
		@INVOKER INT,
		@RETCODE INT OUTPUT,
		@MENSAJE NVARCHAR(MAX) OUTPUT

	AS
		SET @RETCODE = 0
		SET @MENSAJE = 'Empresa insertada'


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
		-- Recuperacion de los datos del JSON entrante
	BEGIN TRY

		BEGIN TRANSACTION

			SELECT @CORREO = Correo, 
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
					WITH (Correo VARCHAR(255) '$.Correo',
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



			-- Comprobaciones de que los campos obligatorios tienen informacion

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
			

			-- Comrpobaciones de que no exista la empresa y ciertas comprobaciones de validaciones y asegurarme de que no
				--hay campos unicos ya insertados

				-- Comprobar que no existe el correo
			IF(@RETCODE = 0)
			BEGIN
				SET @JSON_PRUEBA = (
				SELECT 
				u.id
				FROM Usuario u
				where U.Correo = @CORREO and u.Eliminado = 0
				FOR JSON PATH)

				If (@JSON_PRUEBA is not null or @JSON_PRUEBA != '')
					BEGIN
						SET @RETCODE = 4
						SET @MENSAJE = 'Correo ya existente'
						SET @JSON_OUT = '{"Exito":false}'
					END
				ELSE
					BEGIN
				-- comprobar que no existe el nick	
					SET @JSON_PRUEBA = (
						SELECT 
						u.Nick
						FROM Usuario u
						where U.Nick = @NICK and u.Eliminado = 0
					FOR JSON PATH)

					IF (@JSON_PRUEBA is not null or @JSON_PRUEBA != '')
						BEGIN
							SET @RETCODE = 5
							SET @MENSAJE = 'Nick ya existente'
							SET @JSON_OUT = '{"Exito":false}'
						END
					ELSE
						BEGIN
					-- Comprobar que no se repite el nombre de la empresa
						SET @JSON_PRUEBA = (
							SELECT 
							e.Nombre_Empresa
							FROM Empresa e
							where e.Nombre_Empresa = @NOMBRE_EMPRESA and e.Eliminado = 0
						FOR JSON PATH)

						IF (@JSON_PRUEBA is not null or @JSON_PRUEBA != '')
							BEGIN
								SET @RETCODE = 6
								SET @MENSAJE = 'Nombre de empresa en uso'
								SET @JSON_OUT = '{"Exito":false}'
							END
						ELSE
							BEGIN
					-- Comprobar CIF de la empresa
							SET @JSON_PRUEBA = (
								SELECT 
								e.Cif
								FROM Empresa e
								WHERE e.Cif = @CIF and e.Eliminado = 0
							FOR JSON PATH)

							IF (@JSON_PRUEBA is not null or @JSON_PRUEBA != '')
								BEGIN
									SET @RETCODE = 7
									SET @MENSAJE = 'Cif ya existente'
									SET @JSON_OUT = '{"Exito":false}'
								END
								--Cierro else despues de nombre empresa
							END
							-- cierro else depues nick
						END
						-- cierro else despues correo
					END
			END		
		
		

			SET NOCOUNT ON;

			if (@RETCODE = 0)
				BEGIN
				insert into Usuario values (
					@CORREO,
					@CONTRASENA,
					@NICK,
					@FOTO_PERFIL,
					@FOTO_FONDO,
					@TELEFONO,
					@FRASE,
					0)

				insert into Empresa 
					(Id,
					Nombre_Empresa,
					Cif,
					Direccion_Facturacion,
					Direccion_Fiscal,
					Nombre_Persona,
					Apellido1_Persona,
					Apellido2_Persona,
					Dni_Persona,
					Eliminado) 
				VALUES 
					(@@IDENTITY,
					@NOMBRE_EMPRESA,
					@CIF,
					@DIRECCION_FACTURACION,
					@DIRECCION_FISCAL,
					@NOMBRE_PERSONA,
					@APELLIDO1_PERSONA,
					@APELLIDO2_PERSONA,
					@DNI_PERSONA,
					0)

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
		