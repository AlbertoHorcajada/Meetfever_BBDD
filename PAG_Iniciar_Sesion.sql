USE [MeetFever]
GO
/****** Object:  StoredProcedure [dbo].[PAG_Iniciar_Sesion]    Script Date: 15/06/2022 11:22:08 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- ============================================
-- Author: Gonzalo Racero Galán
-- Create date: 23/04/2022
-- Descrption:	Permite iniciar sesión a partir de un usuario y una contraseña
-- ============================================

	ALTER PROCEDURE [dbo].[PAG_Iniciar_Sesion]
	
		@JSON_IN NVARCHAR(MAX), 
		@JSON_OUT NVARCHAR(MAX) OUTPUT,
		@INVOKER INT,
		@RETCODE INT OUTPUT,
		@MENSAJE NVARCHAR(MAX) OUTPUT

	AS
		SET @RETCODE = 0
		SET @MENSAJE = 'Inicio de sesión correcto'
		DECLARE @CORREO VARCHAR(255)
		DECLARE @CONTRASENA VARCHAR(255)
		DECLARE @IDUSUARIO AS INT
		DECLARE @NUMERO_OCURRENCIAS INT
		SET @IDUSUARIO = -1
		SET @NUMERO_OCURRENCIAS = -1

	BEGIN TRY

		SELECT @CORREO = correo, @CONTRASENA = contrasena
			FROM
				OPENJSON (@JSON_IN) WITH (correo VARCHAR(255), contrasena VARCHAR(255))
	
		-- Verificaciones de datos de entrada.
		
		IF (@CORREO IS NULL OR @CORREO = '' OR @CONTRASENA IS NULL OR @CONTRASENA = '')
			BEGIN
				SET @RETCODE = 1
				SET @MENSAJE = 'Datos de inicio de sesión incorrectos.'
			END

		SET NOCOUNT ON;

		-- compruebo si existe el usuario genérico
		SELECT @IDUSUARIO = id
		FROM USUARIO
		WHERE Correo = @CORREO AND Contrasena = @CONTRASENA
	
		-- si ha encontrado una id pregunto de que tabla viene
		IF (@IDUSUARIO != -1)
		BEGIN

			-- pregunto a empresa

			SELECT @NUMERO_OCURRENCIAS = COUNT(Id)
			FROM EMPRESA
			WHERE Id = @IDUSUARIO
			

			-- si es 1 puedo deducir que es una empresa y si es o será por descarte
			-- una persona, porque existir existe, ya lo dedujimos previamente

			IF (@NUMERO_OCURRENCIAS > 0) -- EMPRESA
			BEGIN


				SET @JSON_OUT = ( 
					SELECT   
						USUARIO.Id,
						USUARIO.Correo,
						USUARIO.Contrasena,
						USUARIO.Nick,
						USUARIO.Foto_Perfil,
						USUARIO.Foto_Fondo,
						USUARIO.Telefono,
						USUARIO.Frase,
						EMPRESA.Nombre_Empresa AS 'Nombre_Empresa',
						EMPRESA.Cif AS 'Cif',
						EMPRESA.Direccion_Facturacion AS 'Direccion_Facturacion',
						EMPRESA.Direccion_Fiscal AS 'Direccion_Fiscal',
						EMPRESA.Nombre_Persona AS 'Nombre_Persona',
						EMPRESA.Apellido1_Persona AS 'Apellido1_Persona',
						EMPRESA.Apellido2_Persona AS 'Apellido2_Persona',
						EMPRESA.Dni_Persona AS 'Dni_Persona',
						'EMPRESA' AS 'Tipo'
					FROM USUARIO INNER JOIN EMPRESA
					ON (Usuario.Id = Empresa.Id)
					WHERE USUARIO.Eliminado = 0  AND Empresa.Eliminado = 0 AND Empresa.id = @IDUSUARIO -- miro que no haya sido borrado
				FOR JSON PATH, WITHOUT_ARRAY_WRAPPER) 
			END

			ELSE -- PERSONA
			BEGIN

			SET @JSON_OUT = ( 
					SELECT   
						USUARIO.Id,
						USUARIO.Correo,
						USUARIO.Contrasena,
						USUARIO.Nick,
						USUARIO.Foto_Perfil,
						USUARIO.Foto_Fondo,
						USUARIO.Telefono,
						USUARIO.Frase,
						PERSONA.Dni AS 'Dni',
						PERSONA.Nombre AS 'Nombre',
						PERSONA.Apellido1 AS 'Apellido1',
						PERSONA.Apellido2 AS 'Apellido2',
						Sexo.Id AS 'Sexo.Id',
						Sexo.Sexo AS 'Sexo.Sexo',
						PERSONA.Fecha_Nacimiento AS 'Fecha_Nacimiento',
						'PERSONA' AS 'Tipo'
					FROM USUARIO INNER JOIN PERSONA
					ON (Usuario.Id = Persona.Id) INNER JOIN Sexo
					ON (Sexo.Id = Persona.Sexo)
					WHERE USUARIO.Eliminado = 0 AND PERSONA.Eliminado = 0 AND Persona.id = @IDUSUARIO -- miro que no haya sido borrado
				FOR JSON PATH, WITHOUT_ARRAY_WRAPPER)
			END
		END

		IF (@JSON_OUT IS NULL)
		BEGIN
			SET @RETCODE = 2
			SET @MENSAJE = 'Usuario no encontrado. | ' + @JSON_IN
		END

	END TRY
	BEGIN CATCH
		SET @MENSAJE = SUBSTRING(ERROR_MESSAGE(), 1, 8000)
		SET @RETCODE = -1
	END CATCH
