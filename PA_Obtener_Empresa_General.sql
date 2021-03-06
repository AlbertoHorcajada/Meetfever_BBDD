USE [MeetFever]
GO
/****** Object:  StoredProcedure [dbo].[PA_Obtener_Empresa_General]    Script Date: 15/06/2022 11:11:41 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- ============================================
-- Author: Alberto Horcajada
-- Create date: 24/04/2022
-- Descrption: Este es un procedimiento almacenado que devuelve todos los datos de un usuario Empresa si tiene alguna coincidencia con una cadena de caracteres adquirida
-- ============================================

	ALTER PROCEDURE [dbo].[PA_Obtener_Empresa_General]
	
		@JSON_IN NVARCHAR(MAX), 
		@JSON_OUT NVARCHAR(MAX) OUTPUT,
		@INVOKER INT,
		@RETCODE INT OUTPUT,
		@MENSAJE NVARCHAR(MAX) OUTPUT

	AS
		SET @RETCODE = 0
		SET @MENSAJE = 'Empresa encontrada'
		DECLARE @PALABRA VARCHAR(255)

		DECLARE @JSON_ELIMINADO NVARCHAR(MAX)
		DECLARE @ELIMINADO BIT
		-- Recuperacion del ID del JSON entrante
	BEGIN TRY

		SELECT @PALABRA = Palabra
			FROM
				OPENJSON (@JSON_IN) WITH (Palabra VARCHAR(255) '$.Palabra')
		-- Comrpobaciones de la palabra
		
		IF (@PALABRA IS NULL)
			BEGIN
				SET @RETCODE = 1
				SET @MENSAJE = 'Palabra nula'
				SET @JSON_OUT = '{"Exito":false}'
			END

		IF (@PALABRA = '')
			BEGIN
				SET @RETCODE = 2
				SET @MENSAJE = 'Palabra vacia'
				SET @JSON_OUT = '{"Exito":false}'
			END

		SET NOCOUNT ON;

		-- Buscar en la BBDD el Usuario por ID y crear el JSON
		IF (@RETCODE = 0)
			BEGIN
				SET @JSON_OUT = (
			
					SELECT DISTINCT
					u.Id,
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
					where u.Eliminado = 0 
					AND e.Eliminado = 0 
					AND (u.Correo LIKE   '%' +@PALABRA + '%' OR
						u.Nick LIKE   '%' +@PALABRA + '%' OR
						u.Frase LIKE   '%' +@PALABRA + '%' OR
						e.Nombre_Empresa LIKE   '%' +@PALABRA + '%')
				
					FOR JSON PATH)

				-- Dos comprobaciones para asegurarnos de que está bien el JSON

				IF (@JSON_OUT = '')
					BEGIN
						SET @RETCODE = 3
						SET @MENSAJE = 'JSON vacio'
						SET @JSON_OUT = '{"Exito":false}'
					END
		
		
		
				IF(@JSON_OUT IS NULL)
					BEGIN
						SET @RETCODE = 4
						SET @MENSAJE = 'Empresas no encontrado'
						SET @JSON_OUT = '{"Exito":false}'
					END
			END
			

	END TRY
	BEGIN CATCH
		SET @MENSAJE = SUBSTRING(ERROR_MESSAGE(), 1, 8000)
		SET @RETCODE = -1
		SET @JSON_OUT = '{"Exito":false}'
	END CATCH
		