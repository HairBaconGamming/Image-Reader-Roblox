local pixels = {}
local COLOR = loadstring(game:HttpGet("https://raw.githubusercontent.com/HairBaconGamming/Image-Reader-Roblox/refs/heads/main/Colors.lua"))
local JPEG = loadstring(game:HttpGet("https://raw.githubusercontent.com/HairBaconGamming/Image-Reader-Roblox/refs/heads/main/JPEG/Main.lua"))
local PNG =  loadstring(game:HttpGet("https://raw.githubusercontent.com/HairBaconGamming/Image-Reader-Roblox/refs/heads/main/PNG.lua"))

local RUN_SERVICE = game:GetService("RunService")

--[[ data include:
	Width:int
	Height:int
	Data[x][y]:color
	compressionLevel:int
]]

function pixels:BufferToPixels(buffer)
	local data = JPEG.new(buffer) or PNG.new(buffer)
	local datapixels = data["ImageData"]
	if not datapixels then
		datapixels = {}
		local i = 0
		for x = 1,data.Width,1 do
			datapixels[x] = datapixels[x] or {}
			for y = 1,data.Height,1 do
				local c,a = PNG:GetPixel(data,x,y)
				datapixels[x][y] = {c.R*255,c.G*255,c.B*255,a}
				i+=1
				if i % 2000 == 0 then
					RUN_SERVICE.Stepped:Wait()
				end
			end
		end
	end
	return {
		["Width"]=data.Width,
		["Height"]=data.Height,
		["Data"]=datapixels,
		["compressionLevel"]=1
	}
end

function pixels.compress(data)
	if data.compressionLevel == nil then
		data.compressionLevel = 10
	end

	local compressedImage = {}
	-- compressedImage sẽ chứa: { {x, y, sizeX, sizeY, r, g, b, a}, ... }

	for x = 1, data.Width do
		for y = 1, data.Height do
			local pixel = data.Data[x][y]

			-- Index 5 dùng để đánh dấu pixel đã được gộp hay chưa
			if pixel[5] == true then 
				continue
			end

			-- Nếu alpha = 0 (trong suốt) thì bỏ qua luôn
			if pixel[4] == 0 then
				pixel[5] = true
				continue
			end

			-- Bắt đầu thuật toán loang (Greedy Meshing)
			local rangeX = 0
			local rangeY = 0
			local tryX = 0
			local tryY = 0
			local stop = false

			-- Giới hạn loop để tránh treo máy quá lâu (40 block tối đa)
			for i = 1, 100 do
				local startA = 0
				local startB = 0

				-- Mở rộng vùng chọn
				if tryX >= tryY then
					startB = tryY
					tryY = tryY + 1
				else
					startA = tryX
					tryX = tryX + 1
				end

				-- Kiểm tra biên ảnh
				if x + tryX > data.Width or y + tryY > data.Height then
					break
				end

				for a = startA, tryX do
					if stop then break end

					for b = startB, tryY do
						if a == 0 and b == 0 then continue end

						local near = data.Data[x + a][y + b]

						-- Nếu pixel bên cạnh đã được xử lý hoặc trong suốt
						if near[5] == true or near[4] == 0 then
							stop = true
							break
						end

						-- So sánh màu sắc
						local distance = COLOR.GetDeltaE(
							{ pixel[1], pixel[2], pixel[3] },
							{ near[1], near[2], near[3] }
						)

						-- Nếu màu khác quá xa -> Dừng mở rộng
						if distance > data.compressionLevel then
							stop = true
							break
						end
					end
				end

				if stop then break end

				rangeX = tryX
				rangeY = tryY
			end

			-- Đánh dấu các pixel trong vùng vừa gộp là "đã xử lý"
			for a = 0, rangeX do
				for b = 0, rangeY do
					local nX = x + a
					local nY = y + b
					if nX <= data.Width and nY <= data.Height then
						data.Data[nX][nY][5] = true
					end
				end
			end

			-- Lưu thông tin block đã nén vào bảng kết quả
			table.insert(
				compressedImage,
				{
					x, y,               -- Vị trí gốc
					rangeX + 1, rangeY + 1, -- Kích thước (Size X, Size Y)
					pixel[1], pixel[2], pixel[3], pixel[4] -- Màu sắc (R, G, B, A)
				}
			)
		end

		if x % 20 == 0 then
			RUN_SERVICE.Heartbeat:Wait()
		end
	end

	-- TRẢ VỀ DATA ĐÃ NÉN TRỰC TIẾP
	return compressedImage
end

return pixels
