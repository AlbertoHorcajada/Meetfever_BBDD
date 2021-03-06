USE [MeetFever]
GO
/****** Object:  StoredProcedure [dbo].[PAGA_Obtener_4_Experiencias_Mas_Mencionadas_En_Opiniones]    Script Date: 15/06/2022 11:22:49 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- ============================================
-- Author: Gonzalo Racero Galán y Alberto Horcajada
-- Create date: 27/04/2022
-- Descrption:	Obtener las 4 exeriencias mas mencionadas
-- ============================================

ALTER PROCEDURE [dbo].[PAGA_Obtener_4_Experiencias_Mas_Mencionadas_En_Opiniones]
		-- es un get, no necesito esto @JSON_IN NVARCHAR(MAX), 
		@JSON_OUT NVARCHAR(MAX) OUTPUT,
		@INVOKER INT,
		@RETCODE INT OUTPUT,
		@MENSAJE NVARCHAR(MAX) OUTPUT
	AS
		SET @RETCODE = 0
		SET @MENSAJE = 'Encontradas experiencias con mas menciones en opiniones.'
			 
			 
		DECLARE @TOP_EXPERIENCIAS TABLE (
		ID INT
		)

	BEGIN TRY
		
		SET NOCOUNT ON;
		-- HE OPTADO PORQUE UNA EXPERIENCIA TENGA UNA REFERENCIA DE SU EMPRESA
		-- ES DECIR, LO QUE EN SPRING ES UNA MANY TO ONE
		-- HACER LO CONTRARIO (QUE UNA EMPRESA TENGA UNA LISTA DE EXPERIENCIAS) IMPLICARIA CAMBIAR LOS PAS
		-- ADEMÁS DE SER INEFICIENTE PORQUE LAS EXPERIENCIAS NO EXISTEN EN EL MOMENTO QUE SE CREA LA EMPRESA

		-- YO SOLO DEVUELVO LA EXPERIENCIA CON SU CORRESPONDIENTE EMPRESA
		-- TU MISIÓN CONSISTE EN HACER QUE ME DEVUELVA LAS 4 EXPERIENCIAS QUE MAS APARECEN EN LAS OPINIONES MENCIONADAS
		-- EN LAS ÚLTIMAS 24 HORAS O ALGO ASI
		
		if(@INVOKER = 1)
			BEGIN

			INSERT INTO @TOP_EXPERIENCIAS 
				SELECT TOP 4 o.Id_Experiencia
					FROM Opinion o LEFT JOIN Experiencia e
					ON (e.Id = o.Id_Experiencia)
					WHERE o.Eliminado = 0 AND e.Eliminado = 0
					GROUP BY (o.Id_Experiencia)
					order by count(o.id) desc


			SET @JSON_OUT = ( 
					SELECT
						Experiencia.Id,
						Experiencia.Titulo,
						Experiencia.Descripcion,
						Experiencia.Fecha_Celebracion,
						Experiencia.Precio,
						Experiencia.Aforo,
						Experiencia.Foto,
						-- tanto usuario como empresa le pongo el PATH de empresa porque es el objeto que voy a recibir, me da igual que internamente se distinga
						-- entre usuario y empresa
						-- si te parece, puedes evaluar los errores de que no se han encontrado experiencias sobre las cuales se está opinando etc etc
						USUARIO.Id AS 'Empresa.id',
						USUARIO.Correo AS 'Empresa.Correo',
						USUARIO.Contrasena AS 'Empresa.Contrasena',
						USUARIO.Nick AS 'Empresa.Nick',
						USUARIO.Foto_Perfil AS 'Empresa.Foto_Perfil',
						USUARIO.Foto_Fondo AS 'Empresa.Foto_Fondo',
						USUARIO.Telefono AS 'Empresa.Telefono',
						USUARIO.Frase AS 'Empresa.Frase',
						EMPRESA.Nombre_Empresa AS 'Empresa.Nombre_Empresa',
						EMPRESA.Cif AS 'Empresa.Cif',
						EMPRESA.Direccion_Facturacion AS 'Empresa.Direccion_Facturacion',
						EMPRESA.Direccion_Fiscal AS 'Empresa.Direccion_Fiscal',
						EMPRESA.Nombre_Persona AS 'Empresa.Nombre_Persona',
						EMPRESA.Apellido1_Persona AS 'Empresa.Apellido1_Persona',
						EMPRESA.Apellido2_Persona AS 'Empresa.Apellido2_Persona',
						EMPRESA.Dni_Persona AS 'Empresa.Dni_Persona',
						(SELECT COUNT (Opinion.Id) FROM Opinion WHERE Opinion.Id_Experiencia = Empresa.id) AS 'Numero_Menciones',
						(SELECT COUNT (en.Id) FROM Entrada_Persona en WHERE en.Id_Experiencia = Experiencia.Id) AS 'numeroEntradas'
					FROM Experiencia INNER JOIN Usuario ON (Experiencia.Id_Empresa = Usuario.id)
						INNER JOIN Empresa ON (Usuario.Id = Empresa.id)
					WHERE Experiencia.Eliminado = 0 AND Usuario.Eliminado = 0 AND Empresa.Eliminado = 0
						AND Experiencia.id = ANY (select id from @TOP_EXPERIENCIAS)
						-- filtro de que aun no se hayan celebrado
						AND DATEDIFF (SECOND, Experiencia.Fecha_Celebracion ,CURRENT_TIMESTAMP) < 0 
					ORDER BY Numero_Menciones DESC
				FOR JSON PATH)

				IF (@JSON_OUT IS NULL)
					BEGIN
						SET @MENSAJE = 'Experiencias no encontradas'
						SET @RETCODE = 1
						SET @JSON_OUT = '{"Exito":false}'
					END

			END
		ELSE
			BEGIN

			INSERT INTO @TOP_EXPERIENCIAS 
				SELECT TOP 6 o.Id_Experiencia
					FROM Opinion o LEFT JOIN Experiencia e
					ON (e.Id = o.Id_Experiencia)
					WHERE o.Eliminado = 0 AND e.Eliminado = 0
					GROUP BY (o.Id_Experiencia)
					order by count(o.id) desc


			SET @JSON_OUT = ( 
					SELECT
						Experiencia.Id,
						Experiencia.Titulo,
						Experiencia.Descripcion,
						Experiencia.Fecha_Celebracion,
						Experiencia.Precio,
						Experiencia.Aforo,
						Experiencia.Foto,
						-- tanto usuario como empresa le pongo el PATH de empresa porque es el objeto que voy a recibir, me da igual que internamente se distinga
						-- entre usuario y empresa
						-- si te parece, puedes evaluar los errores de que no se han encontrado experiencias sobre las cuales se está opinando etc etc
						USUARIO.Id AS 'Empresa.id',
						USUARIO.Correo AS 'Empresa.Correo',
						USUARIO.Contrasena AS 'Empresa.Contrasena',
						USUARIO.Nick AS 'Empresa.Nick',
						USUARIO.Foto_Perfil AS 'Empresa.Foto_Perfil',
						USUARIO.Foto_Fondo AS 'Empresa.Foto_Fondo',
						USUARIO.Telefono AS 'Empresa.Telefono',
						USUARIO.Frase AS 'Empresa.Frase',
						EMPRESA.Nombre_Empresa AS 'Empresa.Nombre_Empresa',
						EMPRESA.Cif AS 'Empresa.Cif',
						EMPRESA.Direccion_Facturacion AS 'Empresa.Direccion_Facturacion',
						EMPRESA.Direccion_Fiscal AS 'Empresa.Direccion_Fiscal',
						EMPRESA.Nombre_Persona AS 'Empresa.Nombre_Persona',
						EMPRESA.Apellido1_Persona AS 'Empresa.Apellido1_Persona',
						EMPRESA.Apellido2_Persona AS 'Empresa.Apellido2_Persona',
						EMPRESA.Dni_Persona AS 'Empresa.Dni_Persona',
						(SELECT COUNT (Opinion.Id) FROM Opinion WHERE Opinion.Id_Experiencia = Empresa.id) AS 'Numero_Menciones',
						(SELECT COUNT (en.Id) FROM Entrada_Persona en WHERE en.Id_Experiencia = Experiencia.Id) AS 'numeroEntradas'
					FROM Experiencia INNER JOIN Usuario ON (Experiencia.Id_Empresa = Usuario.id)
						INNER JOIN Empresa ON (Usuario.Id = Empresa.id)
					WHERE Experiencia.Eliminado = 0 AND Usuario.Eliminado = 0 AND Empresa.Eliminado = 0
						AND Experiencia.id = ANY (select id from @TOP_EXPERIENCIAS)
						AND DATEDIFF (SECOND, Experiencia.Fecha_Celebracion ,CURRENT_TIMESTAMP) < 0 
					ORDER BY Numero_Menciones
				FOR JSON PATH)

				IF (@JSON_OUT IS NULL)
					BEGIN
						SET @MENSAJE = 'Experiencias no encontradas'
						SET @RETCODE = 1
						SET @JSON_OUT = '{"Exito":false}'
					END
			END

	END TRY
	BEGIN CATCH
		SET @MENSAJE = SUBSTRING(ERROR_MESSAGE(), 1, 8000)
		SET @RETCODE = -1
	END CATCH
