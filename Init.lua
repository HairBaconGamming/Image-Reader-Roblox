local pixels = {}
local COLOR = loadstring(game:HttpGet("https://raw.githubusercontent.com/HairBaconGamming/Image-Reader-Roblox/refs/heads/main/Colors.lua"))()
local JPEG = loadstring(game:HttpGet("https://raw.githubusercontent.com/HairBaconGamming/Image-Reader-Roblox/refs/heads/main/JPEG/Main.lua"))()
local PNG =  loadstring(game:HttpGet("https://raw.githubusercontent.com/HairBaconGamming/Image-Reader-Roblox/refs/heads/main/PNG.lua"))()

local RUN_SERVICE = game:GetService("RunService")

-- [OPTIMIZED] Hàm kiểm tra thời gian thông minh
local function SmartYield(startTime)
	-- Giảm ngưỡng xuống 0.004s (4ms) để game có thời gian render mượt mà (60 FPS cần ~16ms/frame)
	-- Nếu để 0.015s như cũ sẽ chiếm hết tài nguyên frame gây lag
	if os.clock() - startTime > 0.004 then
		RUN_SERVICE.Heartbeat:Wait()
		return os.clock()
	end
	return startTime
end

function pixels:BufferToPixels(buffer)
	local success, data = pcall(function()
		return JPEG.new(buffer) or PNG.new(buffer)
	end)

	if not success or not data then
		warn("Failed to decode image buffer.")
		return nil
	end

	local datapixels = data["ImageData"]
	local clockStart = os.clock()

	if not datapixels then
		datapixels = {}
		for x = 1, data.Width do
			datapixels[x] = datapixels[x] or {}
			
			-- Kiểm tra thời gian ở vòng lặp ngoài để tối ưu
			clockStart = SmartYield(clockStart)
			
			for y = 1, data.Height do
				local c, a = PNG:GetPixel(data, x, y)
				datapixels[x][y] = {c.R*255, c.G*255, c.B*255, a}
				
				-- [OPTIMIZED] Chỉ kiểm tra mỗi 50 pixel để giảm overhead của việc gọi os.clock() liên tục
				if y % 50 == 0 then
					clockStart = SmartYield(clockStart)
				end
			end
		end
	end

	return {
		["Width"] = data.Width,
		["Height"] = data.Height,
		["Data"] = datapixels,
		["compressionLevel"] = 1
	}
end

function pixels.compress(data)
	if data.compressionLevel == nil then
		data.compressionLevel = 10
	end

	local compressedImage = {}
	local clockStart = os.clock()

	local visited = {}
	for x = 1, data.Width do visited[x] = {} end

	for x = 1, data.Width do
		-- Kiểm tra thời gian ở vòng lặp ngoài
		clockStart = SmartYield(clockStart)
		
		for y = 1, data.Height do
			-- [OPTIMIZED] Kiểm tra visited nhanh gọn
			if visited[x][y] then 
				continue
			end

			local pixel = data.Data[x][y]

			if pixel[4] == 0 then
				visited[x][y] = true
				continue
			end

			local rangeX = 0
			local rangeY = 0
			local tryX = 0
			local tryY = 0
			local stop = false

			for i = 1, 100 do
				local startA = 0
				local startB = 0

				if tryX >= tryY then
					startB = tryY
					tryY = tryY + 1
				else
					startA = tryX
					tryX = tryX + 1
				end

				if x + tryX > data.Width or y + tryY > data.Height then
					break
				end

				for a = startA, tryX do
					if stop then break end

					for b = startB, tryY do
						if a == 0 and b == 0 then continue end
						
						if visited[x + a] and visited[x + a][y + b] then
							stop = true
							break
						end

						local near = data.Data[x + a][y + b]

						if near[4] == 0 then
							stop = true
							break
						end

						local distance = COLOR.GetDeltaE(
							{ pixel[1], pixel[2], pixel[3] },
							{ near[1], near[2], near[3] }
						)

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

			for a = 0, rangeX do
				for b = 0, rangeY do
					local nX = x + a
					local nY = y + b
					if nX <= data.Width and nY <= data.Height then
						visited[nX][nY] = true
					end
				end
			end

			table.insert(
				compressedImage,
				{
					x, y,
					rangeX + 1, rangeY + 1,
					pixel[1], pixel[2], pixel[3], pixel[4]
				}
			)
			
			-- [OPTIMIZED] Check định kỳ trong vòng lặp nặng này
			if #compressedImage % 50 == 0 then
				clockStart = SmartYield(clockStart)
			end
		end
	end

	return compressedImage
end

return pixels
