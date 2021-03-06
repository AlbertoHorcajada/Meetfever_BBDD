USE [MeetFever]
GO
/****** Object:  StoredProcedure [dbo].[PA_Actualizar_Empleado]    Script Date: 15/06/2022 11:04:48 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- ============================================
-- Author: Alberto Horcajada
-- Create date: 24/04/2022
-- Descrption: Este es un procedimiento almacenado Actualiza un Empleado
-- ============================================

	ALTER PROCEDURE [dbo].[PA_Actualizar_Empleado]
	
		@JSON_IN NVARCHAR(MAX), 
		@JSON_OUT NVARCHAR(MAX) OUTPUT,
		@INVOKER INT,
		@RETCODE INT OUTPUT,
		@MENSAJE NVARCHAR(MAX) OUTPUT

	AS
		SET @RETCODE = 0
		SET @MENSAJE = 'Empleado actualizado'


		DECLARE @ID INT
		DECLARE @NICK VARCHAR(40)
		DECLARE @CONTRASENA VARCHAR(255)
		DECLARE @ID_EMPRESA INT
		DECLARE @ID_PERFIL INT

		


		DECLARE @JSON_PRUEBA NVARCHAR(MAX)
		DECLARE @ELIMINADO BIT
		-- Recuperacion de los datos del JSON entrante
	BEGIN TRY

		BEGIN TRANSACTION

			SELECT @NICK = Nick, 
				@CONTRASENA = Contrasena, 
				@ID_EMPRESA = Id_Empresa, 
				@ID_PERFIL = Id_Perfil,
				@ID = Id
				FROM
					OPENJSON (@JSON_IN) 
					WITH (Id INT '$.Id',
					Nick VARCHAR(40) '$.Nick',
					Contrasena VARCHAR(255) '$.Contrasena',
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
			
							-- cierro else depues nick
					END
						-- cierro else despues correo
			END
		
			IF(@RETCODE = 0)
				BEGIN
					SET @JSON_PRUEBA = NULL
					SET @JSON_PRUEBA = (
						SELECT	e.Id
							FROM Empleado e
							WHERE e.Id = @ID and eliminado = 0
					FOR JSON AUTO)

					IF (@JSON_PRUEBA IS NULL)
						BEGIN
							SET @RETCODE = 7
							SET @MENSAJE = 'Empleado inexistente o eliminado de forma logica'
							SET @JSON_OUT = '{"Exito":false}'
						END

				END

		

			SET NOCOUNT ON;

			-- Buscar en la BBDD el Usuario por ID y crear el JSON
			if (@RETCODE = 0)
				BEGIN

					update Empleado
						SET 
							Nick = @NICK,
							Constrasena = @CONTRASENA,
							Id_Empresa = @ID_EMPRESA,
							Id_Perfil = @ID_PERFIL				
						WHERE 
							Id = @ID

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
		