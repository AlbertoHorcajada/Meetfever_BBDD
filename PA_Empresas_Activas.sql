USE [MeetFever]
GO
/****** Object:  StoredProcedure [dbo].[PA_Empresas_Activas]    Script Date: 15/06/2022 11:08:31 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- ============================================
-- Author: Alberto Horcajada
-- Create date: 24/04/2022
-- Descrption: Cuenta las Empresas sin eliminado logico
-- ============================================

	ALTER PROCEDURE [dbo].[PA_Empresas_Activas]
	
		--@JSON_IN NVARCHAR(MAX), 
		@JSON_OUT NVARCHAR(MAX) OUTPUT,
		@INVOKER INT,
		@RETCODE INT OUTPUT,
		@MENSAJE NVARCHAR(MAX) OUTPUT

	AS
		SET @RETCODE = 0
		SET @MENSAJE = 'Empresas contadas'

		-- Recuperacion del ID del JSON entrante
	BEGIN TRY

		SET NOCOUNT ON;

		-- Buscar en la BBDD el Usuario por ID y crear el JSON
		IF (@RETCODE = 0)
			BEGIN
				SET @JSON_OUT = (
			
					SELECT COUNT(distinct id ) AS 'Empresas'
					FROM Empresa 
					where Eliminado = 0 
					FOR JSON PATH, WITHOUT_ARRAY_WRAPPER)

				-- Dos comprobaciones para asegurarnos de que está bien el JSON

				IF (@JSON_OUT = '')
					BEGIN
						SET @RETCODE = 3
						SET @MENSAJE = 'Algo salio mal'
						SET @JSON_OUT = '{"Exito":false}'
					END
		
		
		
				IF(@JSON_OUT IS NULL)
					BEGIN
						SET @RETCODE = 4
						SET @MENSAJE = 'Resultados no encontrados'
						SET @JSON_OUT = '{"Exito":false}'
					END
			END
			

	END TRY
	BEGIN CATCH
		SET @MENSAJE = SUBSTRING(ERROR_MESSAGE(), 1, 8000)
		SET @RETCODE = -1
		SET @JSON_OUT = '{"Exito":false}'
	END CATCH
		