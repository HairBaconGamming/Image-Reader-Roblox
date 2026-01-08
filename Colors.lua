local module = {}

function module.RGBtoXYZ(c)
	c[1] = c[1] / 255
	c[2] = c[2] / 255
	c[3] = c[3] / 255
	
	for i = 1, 3 do
		if c[i] > 0.04045 then
			c[i] = math.pow((c[i] + 0.055) / 1.055, 2.4)
		else
			c[i] = c[i] / 12.92
		end
	end
	
	local x = c[1] * 0.4124 + c[2] * 0.3576 + c[3] * 0.1805
	local y = c[1] * 0.2126 + c[2] * 0.7152 + c[3] * 0.0722
	local z = c[1] * 0.0193 + c[2] * 0.1192 + c[3] * 0.9505
	
	return { x * 100, y * 100, z * 100 }
end

function module.XYZtoCIELAB(c)
	local xyz = {
		c[1] / 95.047,
		c[2] / 100,
		c[3] / 108.883
	}
	
	for i = 1, 3 do
		if xyz[i] > 0.008856 then
			xyz[i] = math.pow(xyz[i], 1 / 3)
		else
			xyz[i] = (7.787 * xyz[i]) + (16 / 116)
		end
	end
	
	local l = 116 * xyz[2] - 16
	local a = 500 * (xyz[1] - xyz[2])
	local b = 200 * (xyz[2] - xyz[3])
	
	return { l, a, b }
end


function module.CIELABtoXYZ(c)
	local y = (c[1] + 16) / 116
	local x = (c[2] / 500) + y
	local z = y - (c[3] / 200)
	
	local xyz = { x, y, z }
	
	for i = 1, 3 do
		if math.pow(xyz[i], 3) > 0.008856 then
			xyz[i] = math.pow(xyz[i], 3)
		else
			xyz[i] = (xyz[i] - (16 / 116)) / 7.787
		end
	end
	
	return {
		xyz[1] * 95.047,
		xyz[2] * 100,
		xyz[3] * 108.883
	}
end

function module.XYZtoRGB(c)
	local x = c[1] / 100
	local y = c[2] / 100
	local z = c[3] / 100
	
	local rgb = {
		x * 3.2406 + y * -1.5372 + z * -0.4986,
		x * -0.9689 + y * 1.8758 + z * 0.0415,
		x * 0.0557 + y * -0.2040 + z * 1.0570
	}
	
	for i = 1, 3 do
		if rgb[i] > 0.0031308 then
			rgb[i] = 1.055 * math.pow(rgb[i], 1 / 2.4) - 0.055
		else
			rgb[i] = 12.92 * rgb[i]
		end
	end

	return { rgb[1] * 255, rgb[2] * 255, rgb[3] * 255 }
end

function module.GetDeltaE(c1, c2)
	local xyz1 = module.RGBtoXYZ(c1)
	local xyz2 = module.RGBtoXYZ(c2)
	
	local lab1 = module.XYZtoCIELAB(xyz1)
	local lab2 = module.XYZtoCIELAB(xyz2)
	
	return math.sqrt(
		math.pow(lab1[1] - lab2[1], 2) + math.pow(lab1[2] - lab2[2], 2) + math.pow(lab1[3] - lab2[3], 2)
	)
end

return module
