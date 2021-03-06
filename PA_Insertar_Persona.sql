USE [MeetFever]
GO
/****** Object:  StoredProcedure [dbo].[PA_Insertar_Persona]    Script Date: 15/06/2022 11:10:23 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- ============================================
-- Author: Alberto Horcajada
-- Create date: 24/04/2022
-- Descrption: Este es un procedimiento almacenado Inserta un Usuario Persona
-- ============================================

	ALTER PROCEDURE [dbo].[PA_Insertar_Persona]
	
		@JSON_IN NVARCHAR(MAX), 
		@JSON_OUT NVARCHAR(MAX) OUTPUT,
		@INVOKER INT,
		@RETCODE INT OUTPUT,
		@MENSAJE NVARCHAR(MAX) OUTPUT

	AS
		SET @RETCODE = 0
		SET @MENSAJE = 'Persona insertada'


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
			@DNI = Dni,
			@NOMBRE = Nombre,
			@APELLIDO1 = Apellido1,
			@APELLIDO2 = Apellido2,
			@SEXO = Sexo,
			@FECHA_NACIMIENTO = Fecha_Nacimiento
			FROM
				OPENJSON (@JSON_IN) 
				WITH (Correo VARCHAR(255) '$.Correo',
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
			
	
		-- Validaciones

		IF(@RETCODE = 0)
		BEGIN
			SET @JSON_PRUEBA = NULL
			SET @JSON_PRUEBA = (
			SELECT 
			u.id
			FROM Usuario u
			where U.Correo = @CORREO and Eliminado = 0
			FOR JSON PATH)

			If (@JSON_PRUEBA is not null)
				BEGIN
					SET @RETCODE = 4
					SET @MENSAJE = 'Correo ya existente'
					SET @JSON_OUT = '{"Exito":false}'
				END
			ELSE
				BEGIN
			-- comprobar que no existe el nick
				SET @JSON_PRUEBA = NULL
				SET @JSON_PRUEBA = (
					SELECT 
					u.Nick
					FROM Usuario u
					where U.Nick = @NICK and Eliminado =0
				FOR JSON PATH)

				IF (@JSON_PRUEBA is not null)
					BEGIN
						SET @RETCODE = 5
						SET @MENSAJE = 'Nick ya existente'
						SET @JSON_OUT = '{"Exito":false}'
					END
				ELSE
					BEGIN
					SET @JSON_PRUEBA = NULL
				-- Comprobar que no se repite el Dni
					SET @JSON_PRUEBA = (
						SELECT 
						p.Dni
						FROM Persona p
						where p.Dni = @DNI AND p.Eliminado = 0 AND Dni != null
					FOR JSON PATH)

					IF (@JSON_PRUEBA is not null)
						BEGIN
							SET @RETCODE = 6
							SET @MENSAJE = 'DNI ya existente'
							SET @JSON_OUT = '{"Exito":false}'
						END
					ELSE
						BEGIN
				-- Comprobar CIF de la empresa
						SET @JSON_PRUEBA = NULL
						SET @JSON_PRUEBA = (
							SELECT 
							s.Sexo
							FROM Sexo s
							WHERE s.Id = @SEXO
						FOR JSON PATH)

						IF (@JSON_PRUEBA is null )
							BEGIN
								SET @RETCODE = 7
								SET @MENSAJE = 'Sexo no encontrado en la BBDD'
								SET @JSON_OUT = '{"Exito":false}'
							END
						END
					END
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

							SET IDENTITY_INSERT PERSONA ON

						insert into Persona
							(Id,
							Dni,
							Nombre,
							Apellido1,
							Apellido2,
							Sexo,
							Fecha_Nacimiento,
							Eliminado) 
						values
							(@@IDENTITY,
							@DNI,
							@NOMBRE,
							@APELLIDO1,
							@APELLIDO2,
							@SEXO,
							@FECHA_NACIMIENTO
							,
							0)

								SET IDENTITY_INSERT PERSONA OFF

							SET @JSON_OUT = '{"Exito":true}'
				
					
			END	

		COMMIT TRANSACTION

	END TRY
	BEGIN CATCH
		SET @MENSAJE = SUBSTRING(ERROR_MESSAGE(), 1, 8000)
		SET @RETCODE = -1
		SET @JSON_OUT = '{"Exito":false}'
		ROLLBACK TRANSACTION
	END CATCH
		