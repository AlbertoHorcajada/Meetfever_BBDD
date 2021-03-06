USE [MeetFever]
GO
/****** Object:  StoredProcedure [dbo].[PA_Obtener_Empresa_Por_Cif]    Script Date: 15/06/2022 11:11:47 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- ============================================
-- Author: Alberto Horcajada
-- Create date: 24/04/2022
-- Descrption: Este es un procedimiento almacenado que devuelve todos los datos de un usuario Empresa determinado por un CIF
-- ============================================

	ALTER PROCEDURE [dbo].[PA_Obtener_Empresa_Por_Cif]
	
		@JSON_IN NVARCHAR(MAX), 
		@JSON_OUT NVARCHAR(MAX) OUTPUT,
		@INVOKER INT,
		@RETCODE INT OUTPUT,
		@MENSAJE NVARCHAR(MAX) OUTPUT

	AS
		SET @RETCODE = 0
		SET @MENSAJE = 'Empresa encontrada'
		DECLARE @CIF VARCHAR(9)

		DECLARE @JSON_ELIMINADO NVARCHAR(MAX)
		DECLARE @ELIMINADO BIT
		-- Recuperacion del ID del JSON entrante
	BEGIN TRY

		SELECT @CIF = Cif
			FROM
				OPENJSON (@JSON_IN) WITH (Cif VARCHAR(9) '$.Cif')
		-- Comrpobaciones de ese CIF
		
		IF (@CIF IS NULL)
			BEGIN
				SET @RETCODE = 1
				SET @MENSAJE = 'CIF nulo'
				SET @JSON_OUT = '{"Exito":false}'
			END

		IF (@CIF = '')
			BEGIN
				SET @RETCODE = 2
				SET @MENSAJE = 'CIF vacio'
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
			where e.Cif = @CIF
			FOR JSON PATH, without_array_wrapper)

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
				SET @MENSAJE = 'Empresa no encontrada'
				SET @JSON_OUT = '{"Exito":false}'
			END
		ELSE
			BEGIN
				SET @JSON_ELIMINADO = (
					SELECT e.Eliminado
					FROM Empresa e
					WHERE e.Cif = @CIF
				FOR JSON AUTO)

				SELECT @ELIMINADO = Eliminado
					FROM
						OPENJSON (@JSON_ELIMINADO) WITH (Eliminado BIT '$.Eliminado')

				IF (@ELIMINADO = 1)
					BEGIN	

						SET @JSON_OUT = '{"Exito":false}'
						SET @RETCODE = 5
						SET @MENSAJE = 'Empresa eliminada de forma logica'

					END

			END	

		

		

	END TRY
	BEGIN CATCH
		SET @MENSAJE = SUBSTRING(ERROR_MESSAGE(), 1, 8000)
		SET @RETCODE = -1
		SET @JSON_OUT = '{"Exito":false}'
	END CATCH
		