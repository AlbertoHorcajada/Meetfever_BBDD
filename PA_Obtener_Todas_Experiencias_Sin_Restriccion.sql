USE [MeetFever]
GO
/****** Object:  StoredProcedure [dbo].[PA_Obtener_Todas_Experiencias_Sin_Restriccion]    Script Date: 15/06/2022 11:16:54 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- ============================================
-- Author: Alberto Horcajada
-- Create date: 24/04/2022
-- Descrption: Este es un procedimiento almacenado que devuelve todos los datos de todas las experiencias sin eliminado logico
-- ============================================

	ALTER PROCEDURE [dbo].[PA_Obtener_Todas_Experiencias_Sin_Restriccion]
	
		
		@JSON_OUT NVARCHAR(MAX) OUTPUT,
		@INVOKER INT,
		@RETCODE INT OUTPUT,
		@MENSAJE NVARCHAR(MAX) OUTPUT

	AS
		SET @RETCODE = 0
		SET @MENSAJE = 'Experiencias encontradas'
		

		

		-- Recuperacion del ID del JSON entrante
	BEGIN TRY

		SET NOCOUNT ON;

		

		-- Crear JSON de respuesta a raiz de la consulta

		SET @JSON_OUT = (
			
			SELECT DISTINCT e.Id,
			e.Titulo,
			e.Descripcion,
			e.Fecha_Celebracion,
			e.Precio,
			e.Aforo,
			e.Foto,
			-- Como una Experiencia contiene una empresa le tengo que mandar el objeto de la empresa
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
			(SELECT COUNT (Opinion.Id) FROM Opinion WHERE Opinion.Id_Experiencia = e.id) AS 'Numero_Menciones',
			(SELECT COUNT (en.Id) FROM Entrada_Persona en WHERE en.Id_Experiencia = e.Id) AS 'numeroEntradas'
			FROM Experiencia e INNER JOIN Empresa em ON (e.Id_Empresa = Em.Id) INNER JOIN Usuario u on (em.Id = u.Id)
			WHERE e.Eliminado = 0 and u.Eliminado = 0 and DATEDIFF (SECOND, e.Fecha_Celebracion,CURRENT_TIMESTAMP) < 0
			ORDER BY Numero_Menciones DESC
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
				SET @MENSAJE = 'No hay experiencias'
				SET @JSON_OUT = '{"Exito":false}'
			END	
		

	END TRY
	BEGIN CATCH
		SET @MENSAJE = SUBSTRING(ERROR_MESSAGE(), 1, 8000)
		SET @RETCODE = -1
		SET @JSON_OUT = '{"Exito":false}'
	END CATCH
