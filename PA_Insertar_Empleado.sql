USE [MeetFever]
GO
/****** Object:  StoredProcedure [dbo].[PA_Insertar_Empleado]    Script Date: 15/06/2022 11:09:26 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- ============================================
-- Author: Alberto Horcajada
-- Create date: 24/04/2022
-- Descrption: Este es un procedimiento almacenado Inserta un Empleado
-- ============================================

	ALTER PROCEDURE [dbo].[PA_Insertar_Empleado]
	
		@JSON_IN NVARCHAR(MAX),
		@JSON_OUT NVARCHAR(MAX) OUTPUT,
		@INVOKER INT,
		@RETCODE INT OUTPUT,
		@MENSAJE NVARCHAR(MAX) OUTPUT

	AS
		SET @RETCODE = 0
		SET @MENSAJE = 'Empleado insertado'


		DECLARE @NICK VARCHAR(40)
		DECLARE @CONTRASENA VARCHAR(30)
		DECLARE @ID_EMPRESA INT
		DECLARE @ID_PERFIL INT
		


		DECLARE @JSON_PRUEBA NVARCHAR(MAX)
		DECLARE @ELIMINADO BIT
		-- Recuperacion de los datos del JSON entrante
	BEGIN TRY

		SELECT @NICK = Nick, 
			@CONTRASENA = Contrasena, 
			@ID_EMPRESA = Id_Empresa, 
			@ID_PERFIL = Id_Perfil
			FROM
				OPENJSON (@JSON_IN) 
				WITH (Nick VARCHAR(40) '$.Nick',
				Contrasena VARCHAR(30) '$.Contrasena',
				Id_Empresa INT '$.Id_Empresa',
				Id_Perfil INT '$.Id_Perfil')



		-- Comprobaciones de que los campos obligatorios tienen informacion

		if(@NICK IS NULL or @NICK = '')
			BEGIN
				SET @RETCODE = 1
				SET @MENSAJE =  'Nick vacio'
				SET @JSON_OUT = '{"Exito":false}'
			END

		ELSE IF (@CONTRASENA IS NULL or @CONTRASENA = '')
			BEGIN
				SET @RETCODE = 2
				SET @RETCODE = 'Contraseña vacia'
				SET @JSON_OUT = '{"Exito":false}'
			END

		ELSE IF(@ID_EMPRESA IS NULL)
			BEGIN
				SET @RETCODE = 3
				SET @MENSAJE = 'Empresa vacia'
				SET @JSON_OUT = '{"Exito":false}'
			END
		ELSE IF (@ID_PERFIL IS NULL)
			BEGIN
				SET @RETCODE = 4
				SET @MENSAJE = 'Perfil vacio'
				SET @JSON_OUT = '{"Exito":false}'
			END

		-- Comrpobaciones de que las claves foraneas existen

			-- Comprobar que existe la empresa
		IF(@RETCODE = 0)
		BEGIN
			SET @JSON_PRUEBA = (
			SELECT 
			e.Id
			FROM Empresa e
			where e.Id = @ID_EMPRESA
			FOR JSON PATH)

			If (@JSON_PRUEBA is null or @JSON_PRUEBA = '')
				BEGIN
					SET @RETCODE = 5
					SET @MENSAJE = 'No existe la empresa'
					SET @JSON_OUT = '{"Exito":false}'
				END
			ELSE
				BEGIN
			-- comprobar que existe el perfil	
				SET @JSON_PRUEBA = (
					SELECT 
					p.Id
					FROM Perfil p
					where p.Id = @ID_PERFIL
				FOR JSON PATH)

				IF (@JSON_PRUEBA is null or @JSON_PRUEBA = '')
					BEGIN
						SET @RETCODE = 6
						SET @MENSAJE = 'No existe el perfil'
						SET @JSON_OUT = '{"Exito":false}'
					END
			
				END
		END
		
		
		

		SET NOCOUNT ON;

		if (@RETCODE = 0)
			BEGIN

			insert into Empleado
				(Nick,
				Constrasena,
				Id_Empresa,
				Id_Perfil,
				Eliminado) 
			values
				(@NICK,
				@CONTRASENA,
				@ID_EMPRESA,
				@ID_PERFIL,
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
		