USE [MeetFever]
GO
/****** Object:  StoredProcedure [dbo].[PA_Obtener_Entradas_Por_Experiencia]    Script Date: 05/06/2022 18:06:33 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- ============================================
-- Author: Alberto Horcajada
-- Create date: 24/04/2022
-- Descrption: Este es un procedimiento almacenado que devuelve todas las entradas compradaas de una experiencia
-- ============================================

	ALTER PROCEDURE [dbo].[PA_Obtener_Entradas_Por_Experiencia]
	
		@JSON_IN NVARCHAR(MAX), 
		@JSON_OUT NVARCHAR(MAX) OUTPUT,
		@INVOKER INT,
		@RETCODE INT OUTPUT,
		@MENSAJE NVARCHAR(MAX) OUTPUT

	AS
		SET @RETCODE = 0
		SET @MENSAJE = 'entradas encontradas exitosamente'
		DECLARE @ID_EXPERIENCIA INT

		DECLARE @JSONPRUEBA NVARCHAR(MAX)

		-- Recuperacion del ID del JSON entrante
	BEGIN TRY

		SELECT @ID_EXPERIENCIA = Id_Experiencia
			FROM
				OPENJSON (@JSON_IN) WITH (Id_Experiencia INT '$.Id')
		-- Comrpobaciones de ese ID
		
		IF (@ID_EXPERIENCIA IS NULL)
			BEGIN
				SET @RETCODE = 1
				SET @MENSAJE = 'ID nulo'
				SET @JSON_OUT = '{"Exito":false}'
			END

		ELSE IF (@ID_EXPERIENCIA = '')
			BEGIN
				SET @RETCODE = 2
				SET @MENSAJE = 'ID vacio'
				SET @JSON_OUT = '{"Exito":false}'
			END

		ELSE IF (@ID_EXPERIENCIA <0)
			BEGIN
				SET @RETCODE = 3
				SET @MENSAJE = 'ID no valido, numero negativo'
				SET @JSON_OUT = '{"Exito":false}'
			END

		IF (@RETCODE = 0)
			BEGIN
				SET @JSONPRUEBA = (
					SELECT Id
					From Experiencia
					WHERE Id = @ID_EXPERIENCIA AND Eliminado = 0
				)

				IF (@JSONPRUEBA IS NULL)
					BEGIN
						SET @RETCODE = 4
						SET @MENSAJE = 'No existe la experiencia o borrada de forma logica'
						SET @JSON_OUT = '{"Exito":false}'
					END

			END

		SET NOCOUNT ON;

		-- Crear JSON de respuesta a raiz de la consulta
	IF (@RETCODE = 0)
	BEGIN
		SET @JSON_OUT = (
			
			SELECT DISTINCT
			-- XDDDDD solo necesito el count
			COUNT(e.Id) AS 'Entradas_Vendidas'
			/*-- Paso la persona que se encargó de comprar la entrada
			u.id AS 'Persona.Id',
			u.Correo AS 'Persona.Correo',
			u.Contrasena AS 'Persona.Contrasena',
			u.Nick AS 'Persona.Nick',
			u.Foto_Fondo AS 'Persona.Foto_Fondo',
			u.Foto_Perfil AS 'Persona.Foto_Perfil',
			u.Telefono AS 'Persona.Telefono',
			u.Frase AS 'Persona.Frase',
			p.Dni AS 'Persona.Dni',
			p.Nombre AS 'Persona.Nombre',
			p.Apellido1 AS 'Persona.Apellido1',
			p.Apellido2 AS 'Persona.Apellido2',
			s.Id AS 'Persona.Sexo.Id',
			s.Sexo AS 'Persona.Sexo.Sexo',
			p.Fecha_Nacimiento AS 'Persona.Fecha_Nacimiento',
			-- Paso la experiencia de la que se compra la entrada
			ex.Id AS 'Experiencia.Id',
			ex.Titulo AS 'Experiencia.Titulo',
			ex.Descripcion AS 'Experiencia.Descripcion',
			ex.Fecha_Celebracion AS 'Experiencia.Fecha_Celebracion',
			ex.Precio AS 'Experiencia.Precio',
			ex.Aforo AS 'Experiencia.Aforo',
			ex.Foto AS 'Experiencia.Foto',
			-- Como una Experiencia contiene una empresa le tengo que mandar el objeto de la empresa
			u.id AS 'Experiencia.Empresa.Id',
			u.Correo AS 'Experiencia.Empresa.Correo',
			u.Contrasena AS 'Experiencia.Empresa.Contrasena',
			u.Nick AS 'Experiencia.Empresa.Nick',
			u.Foto_Fondo AS 'Experiencia.Empresa.Foto_Fondo',
			u.Foto_Perfil AS 'Experiencia.Empresa.Foto_Perfil',
			u.Telefono AS 'Experiencia.Empresa.Telefono',
			u.Frase AS 'Experiencia.Empresa.Frase',
			em.Nombre_Empresa AS 'Experiencia.Empresa.Nombre_Empresa', 
			em.Cif AS 'Experiencia.Empresa.Cif', 
			em.Direccion_Facturacion AS 'Experiencia.Empresa.Direccion_Facturacion', 
			em.Direccion_Fiscal AS 'Experiencia.Empresa.Direccion_Fiscal', 
			em.Nombre_Persona AS 'Experiencia.Empresa.Nombre_Persona', 
			em.Apellido1_Persona AS 'Experiencia.Empresa.Apellido1_Persona', 
			em.Apellido2_Persona AS 'Experiencia.Empresa.Apellido2_Persona',
			em.Dni_Persona AS 'Experiencia.Empresa.Dni_Persona',
			-- Resto de datos que contiene una entrada
			e.Fecha,
			e.Nombre,
			e.Apellido1,
			e.Apellido2,
			e.Dni,
			e.Id_paypal*/
			

			FROM Entrada_Persona e
			/*INNER JOIN Persona p on (e.Id_Persona = p.Id) 
					INNER JOIN Usuario u ON (u.Id = p.Id)
					INNER JOIN Experiencia ex ON (ex.Id = e.Id_Experiencia)
					INNER JOIN Empresa em ON (em.Id = ex.Id_Empresa)
					INNER JOIN Sexo s ON (s.Id = p.Sexo)*/
			WHERE e.Id_Experiencia = @ID_EXPERIENCIA and e.eliminado = 0
			FOR JSON PATH, WITHOUT_ARRAY_WRAPPER)


		-- Dos comprobaciones para asegurarnos de que está bien el JSON

		IF (@JSON_OUT = '')
			BEGIN
				SET @RETCODE = 5
				SET @MENSAJE = 'JSON vacio'
				SET @JSON_OUT = '{"Exito":false}'
			END


		IF(@JSON_OUT IS NULL)
			BEGIN
				SET @RETCODE = 6
				SET @MENSAJE = 'Experiencias no encontradas'
				SET @JSON_OUT = '{"Exito":false}'
			END
		
	END
	END TRY
	BEGIN CATCH
		SET @MENSAJE = SUBSTRING(ERROR_MESSAGE(), 1, 8000)
		SET @RETCODE = -1
		SET @JSON_OUT = '{"Exito":false}'
	END CATCH
