USE [MeetFever]
GO
/****** Object:  StoredProcedure [dbo].[PA_Obtener_Todas_Empresas_Sin_Borrado]    Script Date: 07/06/2022 21:22:52 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- ============================================
-- Author: Alberto Horcajada
-- Create date: 24/04/2022
-- Descrption: Este es un procedimiento almacenado que devuelve todos los datos de todos los usuarios Empresa
-- ============================================

	ALTER PROCEDURE [dbo].[PA_Obtener_Todas_Empresas_Sin_Borrado]
	
		@JSON_OUT NVARCHAR(MAX) OUTPUT,
		@INVOKER INT,
		@RETCODE INT OUTPUT,
		@MENSAJE NVARCHAR(MAX) OUTPUT

	AS
		SET @RETCODE = 0
		SET @MENSAJE = 'Empresas devueltas'

		-- Recuperacion del ID del JSON entrante
	BEGIN TRY

		SET NOCOUNT ON;

		-- Crear JSON de respuesta a raiz de la consulta

		SET @JSON_OUT = (
			
			SELECT DISTINCT u.Id,
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
					e.Dni_Persona,
					e.Eliminado
			FROM Usuario u INNER JOIN Empresa e ON (u.Id = e.Id)
			FOR JSON PATH)


		-- Dos comprobaciones para asegurarnos de que está bien el JSON

		IF (@JSON_OUT = '')
			BEGIN
				SET @RETCODE = 1
				SET @MENSAJE = 'JSON vacio'
				SET @JSON_OUT = '{"Exito":false}'
			END


		IF(@JSON_OUT IS NULL)
			BEGIN
				SET @RETCODE = 2
				SET @MENSAJE = 'Empresas no encontradas'
				SET @JSON_OUT = '{"Exito":false}'
			END
		

		

		

	END TRY
	BEGIN CATCH
		SET @MENSAJE = SUBSTRING(ERROR_MESSAGE(), 1, 8000)
		SET @RETCODE = -1
	END CATCH
