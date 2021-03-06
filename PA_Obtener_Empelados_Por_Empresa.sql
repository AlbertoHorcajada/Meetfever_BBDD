USE [MeetFever]
GO
/****** Object:  StoredProcedure [dbo].[PA_Obtener_Empelados_Por_Empresa]    Script Date: 15/06/2022 11:11:32 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- ============================================
-- Author: Alberto Horcajada
-- Create date: 24/04/2022
-- Descrption: Este es un procedimiento almacenado que devuelve todos los datos de los empleados dada una empresa
-- ============================================

	ALTER PROCEDURE [dbo].[PA_Obtener_Empelados_Por_Empresa]
	
		@JSON_IN NVARCHAR(MAX), 
		@JSON_OUT NVARCHAR(MAX) OUTPUT,
		@INVOKER INT,
		@RETCODE INT OUTPUT,
		@MENSAJE NVARCHAR(MAX) OUTPUT

	AS
		SET @RETCODE = 0
		SET @MENSAJE = 'Empleados encontrados'
		DECLARE @ID_EMPRESA INT

		DECLARE @JSONPRUEBA NVARCHAR(MAX)

		-- Recuperacion del ID del JSON entrante
	BEGIN TRY

		SELECT @ID_EMPRESA = Id_Empresa
			FROM
				OPENJSON (@JSON_IN) WITH (Id_Empresa INT '$.Id')
		-- Comrpobaciones de ese ID
		
		IF (@ID_EMPRESA IS NULL)
			BEGIN
				SET @RETCODE = 1
				SET @MENSAJE = 'ID nulo'
				SET @JSON_OUT = '{"Exito":false}'
			END

		ELSE IF (@ID_EMPRESA = '')
			BEGIN
				SET @RETCODE = 2
				SET @MENSAJE = 'ID vacio'
				SET @JSON_OUT = '{"Exito":false}'
			END

		ELSE IF (@ID_EMPRESA <0)
			BEGIN
				SET @RETCODE = 3
				SET @MENSAJE = 'ID no valido, numero negativo'
				SET @JSON_OUT = '{"Exito":false}'
			END

		IF (@RETCODE = 0)
			BEGIN
				SET @JSONPRUEBA = (
					SELECT Id
					From Empresa
					WHERE Id = @ID_EMPRESA AND Eliminado = 0
				)

				IF (@JSONPRUEBA IS NULL)
					BEGIN
						SET @RETCODE = 4
						SET @MENSAJE = 'No existe la empresa o borrada de forma logica'
						SET @JSON_OUT = '{"Exito":false}'
					END

			END

		
		SET NOCOUNT ON;

	

		-- Crear JSON de respuesta a raiz de la consulta

		IF (@RETCODE =0)
		BEGIN

			SET @JSON_OUT = (
				
				SELECT 
				e.Id,
				e.Nick,
				e.Constrasena,
				u.id AS 'Empresa.Id',
				u.Correo AS 'Empresa.Correo',
				u.Contrasena AS 'Empresa.Contrasena',
				u.Nick AS 'Empresa.Nick',
				u.Foto_Fondo AS 'Empresa.Foto_Fondo',
				u.Foto_Perfil AS 'Empresa.Foto_Perfil',
				u.Telefono AS 'Empresa.Telefono',
				u.Frase AS 'Empresa.Frase',
				em.Nombre_Empresa AS 'Empresa.Nombre_Empresa', 
				em.Cif AS 'Empresa.Cif', 
				em.Direccion_Facturacion AS 'Empresa.Direccion_Facturacion', 
				em.Direccion_Fiscal AS 'Empresa.Direccion_Fiscal', 
				em.Nombre_Persona AS 'Empresa.Nombre_Persona', 
				em.Apellido1_Persona AS 'Empresa.Apellido1_Persona', 
				em.Apellido2_Persona AS 'Empresa.Apellido2_Persona',
				em.Dni_Persona AS 'Empresa.Dni_Persona',
				p.Id AS 'Perfil.Id',
				p.Cargo AS 'Perfil.Cargo'

				FROM Empleado e INNER JOIN Empresa em on (e.Id_Empresa = em.Id) 
					INNER JOIN Usuario u ON (u.Id = em.Id)
					INNER JOIN Perfil p ON (e.Id_Perfil = p.Id)
				WHERE e.Id_Empresa = @ID_EMPRESA and e.eliminado = 0
				FOR JSON PATH)

		-- Dos comprobaciones para asegurarnos de que está bien el JSON

		IF (@JSON_OUT = '')
			BEGIN
				SET @RETCODE = 4
				SET @MENSAJE = 'JSON vacio'
				SET @JSON_OUT = '{"Exito":false}'
			END


		IF(@JSON_OUT IS NULL)
			BEGIN
				SET @RETCODE = 5
				SET @MENSAJE = 'Empleados no encontrados'
				SET @JSON_OUT = '{"Exito":false}'
			END
		
	END
	END TRY
	BEGIN CATCH
		SET @MENSAJE = SUBSTRING(ERROR_MESSAGE(), 1, 8000)
		SET @RETCODE = -1
		SET @JSON_OUT = '{"Exito":false}'
	END CATCH
