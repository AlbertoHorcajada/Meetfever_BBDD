USE [MeetFever]
GO
/****** Object:  StoredProcedure [dbo].[PA_Actualizar_Persona]    Script Date: 15/06/2022 11:05:31 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- ============================================
-- Author: Alberto Horcajada
-- Create date: 24/04/2022
-- Descrption: Este es un procedimiento almacenado Actualizar un Usuario Persona
-- ============================================

	ALTER PROCEDURE [dbo].[PA_Actualizar_Persona]
	
		@JSON_IN NVARCHAR(MAX), 
		@JSON_OUT NVARCHAR(MAX) OUTPUT,
		@INVOKER INT,
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
		DECLARE @DNI CHAR (9)
		DECLARE @NOMBRE VARCHAR(50)
		DECLARE @APELLIDO1 VARCHAR(50)
		DECLARE @APELLIDO2 VARCHAR(50)
		DECLARE @SEXO INT
		DECLARE @FECHA_NACIMIENTO DATE


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
				@DNI = Dni,
				@NOMBRE = Nombre,
				@APELLIDO1 = Apellido1,
				@APELLIDO2 = Apellido2,
				@SEXO = Sexo,
				@FECHA_NACIMIENTO = Fecha_Nacimiento
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
					Dni CHAR(9) '$.Dni',
					Nombre VARCHAR(50) '$.Nombre',
					Apellido1 VARCHAR(50) '$.Apellido1',
					Apellido2 VARCHAR(50) '$.Apellido2',
					Sexo INT '$.Sexo.Id',
					Fecha_Nacimiento DATE '$.Fecha_Nacimiento')

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
					SET @MENSAJE = 'Id Vacio'
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
						where U.Nick = @NICK AND u.Id != @ID
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
							p.Dni
							FROM Persona p
							where p.Dni = @DNI AND p.Id != @ID
						FOR JSON PATH)

						IF (@JSON_PRUEBA is not null or @JSON_PRUEBA != '')
							BEGIN
								SET @RETCODE = 7
								SET @MENSAJE = 'DNI ya existente'
								SET @JSON_OUT = '{"Exito":false}'
							END
						ELSE
							BEGIN
							SET @JSON_PRUEBA = (
								SELECT 
								s.Sexo
								FROM Sexo s
								WHERE s.Id = @SEXO
							FOR JSON PATH)

							IF (@JSON_PRUEBA is null or @JSON_PRUEBA = '')
								BEGIN
									SET @RETCODE = 8
									SET @MENSAJE = 'Sexo inexistente'
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
						SELECT p.Id
							FROM Persona p
								WHERE p.Id = @ID AND p.Eliminado = 0
					FOR JSON AUTO)

					IF (@JSON_PRUEBA IS NULL)
						BEGIN
							SET @RETCODE = 9
							SET @MENSAJE = 'No existe la Persona o borrada de forma logica'
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

				UPDATE Persona
					SET
						Dni = @DNI,
						Nombre = @NOMBRE,
						Apellido1 = @APELLIDO1,
						Apellido2 = @APELLIDO2,
						Sexo = @SEXO,
						Fecha_Nacimiento = @FECHA_NACIMIENTO
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
		