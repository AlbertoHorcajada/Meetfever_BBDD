USE [MeetFever]
GO
/****** Object:  StoredProcedure [dbo].[PA_Obtener_Empresa_Por_Correo]    Script Date: 15/06/2022 11:11:55 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- ============================================
-- Author: Alberto Horcajada
-- Create date: 24/04/2022
-- Descrption: Este es un procedimiento almacenado que devuelve todos los datos de un usuario Empresa determinado por un correo
-- ============================================

	ALTER PROCEDURE [dbo].[PA_Obtener_Empresa_Por_Correo]
	
		@JSON_IN NVARCHAR(MAX), 
		@JSON_OUT NVARCHAR(MAX) OUTPUT,
		@INVOKER INT,
		@RETCODE INT OUTPUT,
		@MENSAJE NVARCHAR(MAX) OUTPUT

	AS
		SET @RETCODE = 0
		SET @MENSAJE = 'Empresa encontrada'
		DECLARE @CORREO VARCHAR(255)

		DECLARE @JSON_ELIMINADO NVARCHAR(MAX)
		DECLARE @ELIMINADO BIT
		-- Recuperacion del ID del JSON entrante
	BEGIN TRY

		SELECT @CORREO = Correo
			FROM
				OPENJSON (@JSON_IN) WITH (Correo VARCHAR(255) '$.Correo')
		-- Comrpobaciones de ese correo
		
		IF (@CORREO IS NULL)
			BEGIN
				SET @RETCODE = 1
				SET @MENSAJE = 'Correo nulo'
				SET @JSON_OUT = '{"Exito":false}'
			END

		IF (@CORREO = '')
			BEGIN
				SET @RETCODE = 2
				SET @MENSAJE = 'Correo vacio'
				SET @JSON_OUT = '{"Exito":false}'
			END

		SET NOCOUNT ON;

		-- Buscar en la BBDD el Usuario por ID y crear el JSON

		SET @JSON_OUT = (
			
			SELECT 
			u.id,
			u.Correo,
			u.Contrasena,
			u.Nick,
			u.Foto_Fondo,
			u.Foto_Perfil,
			u.Telefono,
			u.Frase,
			e.Nombre_Empresa, 
			e.Cif, 
			e.Direccion_Facturacion, 
			e.Direccion_Fiscal, 
			e.Nombre_Persona, 
			e.Apellido1_Persona, 
			e.Apellido2_Persona,
			e.Dni_Persona

			FROM Empresa e INNER JOIN Usuario u ON (u.Id = e.Id)
			where U.Correo = @CORREO
			FOR JSON PATH)

		-- Dos comprobaciones para asegurarnos de que está bien el JSON

		IF (@JSON_OUT = '')
			BEGIN
				SET @RETCODE = 3
				SET @MENSAJE = 'JSON vacio'
			END
		
		
		
		IF(@JSON_OUT IS NULL)
			BEGIN
				SET @RETCODE = 4
				SET @MENSAJE = 'Empresa no encontrada'
			END
		ELSE
			BEGIN
				SET @JSON_ELIMINADO = (
					SELECT u.Eliminado
					FROM Usuario u
					WHERE u.Correo = @CORREO
				FOR JSON AUTO)

				SELECT @ELIMINADO = Eliminado
					FROM
						OPENJSON (@JSON_ELIMINADO) WITH (Eliminado BIT '$.Eliminado')

				IF (@ELIMINADO = 1)
					BEGIN	

						SET @JSON_OUT = '{"Exito":false}'
						SET @RETCODE = 5
						SET @MENSAJE = 'Empresa eliminado de forma logica'

					END

			END	

		

		

	END TRY
	BEGIN CATCH
		SET @MENSAJE = SUBSTRING(ERROR_MESSAGE(), 1, 8000)
		SET @RETCODE = -1
		SET @JSON_OUT = '{"Exito":false}'
	END CATCH
		