--// BAAN HUB v9 DISTRIBUTION - key system + AES-256 encrypted payload
local KEY_URL = "https://pastebin.com/raw/LRU4XByY"          -- raw paste url with sha256 lines (fallback mode)
local TOKEN_API = "https://work.ink/_api/v2/token/isValid/"  -- work.ink key system (unique token per user); empty = pastebin mode
local GET_KEY_URL = "https://work.ink/2Tq7/baanhub-key"      -- shown in prompt: where users get a key/token
local HWID_LOCK = false     -- true = each key works on one device only
local KEY_FILE = "baan_hub_key.txt"
local KEY_UNTIL_FILE = "baan_hub_key_until.txt"
local KEY_TTL = 3 * 60 * 60 -- seconds a validated key stays activated (3 hours)
local DEV_KEYS = { "BAANHUB-TEST" }

local PAYLOAD_KEY = "tNqcyuo1/b9/0fiM4joOnb0HAvUgzvgNL5DVStGSDUo="
local PAYLOAD_IV = "rkn/vDqVYOXHlzvPHmqZ7w=="
local PAYLOAD_CT = "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"

local genv = getgenv()
genv.__autoSea = genv.__autoSea or {}
local S = genv.__autoSea

-- genv survives rejoins but GUIs do not: reset gate flags on every new server
if S.lastJoinId ~= game.JobId then
	S.lastJoinId = game.JobId
	S.keyOk = false
	S.keyGuiUp = false
end

local function log(...)
	print("[baan-hub]", ...)
end

---------------------------------------------------------------------
-- KEY SYSTEM
do
	local function hwid()
		local cid = ""
		pcall(function()
			cid = game:GetService("RbxAnalyticsService"):GetClientId()
		end)
		return tostring(game.Players.LocalPlayer.UserId) .. "|" .. tostring(cid)
	end

	local function keyHash(key)
		return crypt.hash(HWID_LOCK and (key .. "::" .. hwid()) or key, "sha256")
	end

	local allowed = {}
	if KEY_URL ~= "" then
		local okR, body = pcall(function()
			return request({ Url = KEY_URL, Method = "GET" }).Body
		end)
		if okR and type(body) == "string" and #body > 10 then
			for line in body:gmatch("[^\r\n]+") do
				table.insert(allowed, (line:lower():gsub("%s", "")))
			end
		else
			log("key list fetch failed; using dev keys")
		end
	end
	if #allowed == 0 then
		for _, k in ipairs(DEV_KEYS) do
			table.insert(allowed, keyHash(k))
		end
	end

	local function valid(key)
		local h = keyHash(key:gsub("%s", ""))
		for _, a in ipairs(allowed) do
			if a == h then return true end
		end
		return false
	end

	-----------------------------------------------------------------
	-- WORK.INK MODE: unique token per user, validated on work.ink servers
	if TOKEN_API ~= "" then
		local function hwidTag()
			return crypt.hash(hwid(), "sha256"):sub(1, 16)
		end

		-- single-use validation: consumes the token so sharing it is useless;
		-- grants a fresh KEY_TTL window on this device (work.ink's own expiry
		-- is only a redemption deadline, NOT the session length)
		local function tokenCheck(k)
			if #k < 8 then return nil, "token too short" end
			local okR, body = pcall(function()
				return request({ Url = TOKEN_API .. k .. "?deleteToken=1", Method = "GET" }).Body
			end)
			if not okR or type(body) ~= "string" then return nil, "network error" end
			local okJ, data = pcall(function()
				return game:GetService("HttpService"):JSONDecode(body)
			end)
			if not okJ or type(data) ~= "table" or not data.valid then
				return nil, "invalid or already-used token"
			end
			return os.time() + KEY_TTL
		end

		-- session record: hwidTag|issued|until (bound to this device)
		local sessHw, sessIssued, sessUntil = "", 0, 0
		pcall(function()
			if isfile(KEY_UNTIL_FILE) then
				local a, b, c = (readfile(KEY_UNTIL_FILE) or ""):match("^(%x+)|(%d+)|(%d+)$")
				sessHw, sessIssued, sessUntil = a or "", tonumber(b) or 0, tonumber(c) or 0
			end
		end)

		if sessHw == hwidTag() and os.time() < sessUntil and os.time() >= sessIssued - 60 then
			S.keyOk = true
			S.keyExp = sessUntil
			log(string.format("session active, %d min left", math.floor((sessUntil - os.time()) / 60)))
		else
			log("no valid session - key required")
		end

		if not S.keyOk then
			if not S.keyGuiUp then
				S.keyGuiUp = true

				local lp2 = game.Players.LocalPlayer
				local parent = (type(gethui) == "function" and gethui())
					or game:FindFirstChildOfClass("CoreGui")
					or lp2:WaitForChild("PlayerGui")

				pcall(function()
					local old = parent:FindFirstChild("BaanHubKeys")
					if old then old:Destroy() end
				end)

				local gui = Instance.new("ScreenGui")
				gui.Name = "BaanHubKeys"
				gui.ResetOnSpawn = false
				gui.DisplayOrder = 9999
				gui.Parent = parent

				local frame = Instance.new("Frame")
				frame.Size = UDim2.fromOffset(340, 244)
				frame.Position = UDim2.fromScale(0.5, 0.45)
				frame.AnchorPoint = Vector2.new(0.5, 0.5)
				frame.BackgroundColor3 = Color3.fromRGB(15, 17, 22)
				frame.BorderSizePixel = 0
				frame.Parent = gui
				Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 8)
				local stroke = Instance.new("UIStroke", frame)
				stroke.Color = Color3.fromRGB(255, 196, 60)
				stroke.Thickness = 1.6

				local function label(txt, y, size, color)
					local t = Instance.new("TextLabel")
					t.Size = UDim2.new(1, -24, 0, size + 8)
					t.Position = UDim2.fromOffset(12, y)
					t.BackgroundTransparency = 1
					t.Font = Enum.Font.GothamBold
					t.TextSize = size
					t.TextColor3 = color
					t.TextWrapped = true
					t.TextXAlignment = Enum.TextXAlignment.Left
					t.Text = txt
					t.Parent = frame
					return t
				end

				label("BAAN HUB - Key Required", 10, 18, Color3.fromRGB(255, 196, 60))

				local getBtn = Instance.new("TextButton")
				getBtn.Size = UDim2.new(1, -24, 0, 32)
				getBtn.Position = UDim2.fromOffset(12, 42)
				getBtn.BackgroundColor3 = Color3.fromRGB(255, 196, 60)
				getBtn.TextColor3 = Color3.fromRGB(30, 26, 8)
				getBtn.Font = Enum.Font.GothamBold
				getBtn.TextSize = 15
				getBtn.Text = "GET KEY"
				getBtn.AutoButtonColor = true
				getBtn.Parent = frame
				Instance.new("UICorner", getBtn).CornerRadius = UDim.new(0, 6)

				local hint = label("", 80, 11, Color3.fromRGB(150, 155, 165))

				local function giveLink()
					pcall(function() setclipboard(GET_KEY_URL) end)
					hint.Text = "Link COPIED! Paste it in your browser (Ctrl+V), finish the steps, then copy your token."
				end
				giveLink()
				getBtn.MouseButton1Click:Connect(giveLink)

				local box = Instance.new("TextBox")
				box.Size = UDim2.new(1, -24, 0, 34)
				box.Position = UDim2.fromOffset(12, 122)
				box.BackgroundColor3 = Color3.fromRGB(28, 31, 40)
				box.TextColor3 = Color3.fromRGB(240, 240, 255)
				box.PlaceholderText = "Paste your token..."
				box.PlaceholderColor3 = Color3.fromRGB(110, 115, 125)
				box.ClearTextOnFocus = false
				box.Font = Enum.Font.Code
				box.TextSize = 14
				box.Text = ""
				box.Parent = frame
				Instance.new("UICorner", box).CornerRadius = UDim.new(0, 6)

				local btn = Instance.new("TextButton")
				btn.Size = UDim2.new(1, -24, 0, 34)
				btn.Position = UDim2.fromOffset(12, 164)
				btn.BackgroundColor3 = Color3.fromRGB(30, 160, 90)
				btn.TextColor3 = Color3.fromRGB(235, 255, 240)
				btn.Font = Enum.Font.GothamBold
				btn.TextSize = 16
				btn.Text = "ACTIVATE"
				btn.AutoButtonColor = true
				btn.Parent = frame
				Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)

				local msg = label("", 206, 13, Color3.fromRGB(170, 175, 185))

				btn.MouseButton1Click:Connect(function()
					local k = box.Text:gsub("%s", "")
					if #k < 8 then
						msg.TextColor3 = Color3.fromRGB(255, 90, 90)
						msg.Text = "Paste your token first - press GET KEY above."
						return
					end
					msg.TextColor3 = Color3.fromRGB(170, 175, 185)
					msg.Text = "Checking with server..."
					task.spawn(function()
						local exp, err = tokenCheck(k)
						if exp then
							pcall(function()
								writefile(KEY_FILE, k)
								writefile(KEY_UNTIL_FILE, hwidTag() .. "|" .. os.time() .. "|" .. exp)
							end)
							S.keyExp = exp
							S.keyGuiUp = false
							S.keyOk = true
							gui:Destroy()
							log("token accepted (entered)")
						else
							msg.TextColor3 = Color3.fromRGB(255, 90, 90)
							msg.Text = "Failed: " .. tostring(err)
						end
					end)
				end)
			end
			repeat task.wait(0.25) until S.keyOk
		end
	else

	local saved = ""
	pcall(function()
		if isfile(KEY_FILE) then saved = (readfile(KEY_FILE) or ""):gsub("%s", "") end
	end)

	local function activatedUntil()
		local t = 0
		pcall(function()
			if isfile(KEY_UNTIL_FILE) then t = tonumber(readfile(KEY_UNTIL_FILE)) or 0 end
		end)
		return t
	end

	if #saved > 0 and valid(saved) and os.time() < activatedUntil() then
		S.keyOk = true
		log(string.format("key accepted (saved), %d min left",
			math.floor((activatedUntil() - os.time()) / 60)))
	elseif not S.keyOk then
		if #saved > 0 and valid(saved) then
			log("key expired - get a new one via the link")
		end
		if not S.keyGuiUp then
			S.keyGuiUp = true

			local lp2 = game.Players.LocalPlayer
			local parent = (type(gethui) == "function" and gethui())
				or game:FindFirstChildOfClass("CoreGui")
				or lp2:WaitForChild("PlayerGui")

			local gui = Instance.new("ScreenGui")
			gui.Name = "BaanHubKeys"
			gui.ResetOnSpawn = false
			gui.DisplayOrder = 9999
			gui.Parent = parent

			local frame = Instance.new("Frame")
			frame.Size = UDim2.fromOffset(340, 216)
			frame.Position = UDim2.fromScale(0.5, 0.45)
			frame.AnchorPoint = Vector2.new(0.5, 0.5)
			frame.BackgroundColor3 = Color3.fromRGB(15, 17, 22)
			frame.BorderSizePixel = 0
			frame.Parent = gui
			Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 8)
			local stroke = Instance.new("UIStroke", frame)
			stroke.Color = Color3.fromRGB(255, 196, 60)
			stroke.Thickness = 1.6

			local function label(txt, y, size, color)
				local t = Instance.new("TextLabel")
				t.Size = UDim2.new(1, -24, 0, size + 8)
				t.Position = UDim2.fromOffset(12, y)
				t.BackgroundTransparency = 1
				t.Font = Enum.Font.GothamBold
				t.TextSize = size
				t.TextColor3 = color
				t.TextWrapped = true
				t.TextXAlignment = Enum.TextXAlignment.Left
				t.Text = txt
				t.Parent = frame
				return t
			end

			label("BAAN HUB - Key Required", 10, 18, Color3.fromRGB(255, 196, 60))
			label(GET_KEY_URL ~= "" and ("Get a key: " .. GET_KEY_URL)
				or "Contact the seller to get your key.", 38, 12, Color3.fromRGB(150, 155, 165))

			local box = Instance.new("TextBox")
			box.Size = UDim2.new(1, -24, 0, 34)
			box.Position = UDim2.fromOffset(12, 66)
			box.BackgroundColor3 = Color3.fromRGB(28, 31, 40)
			box.TextColor3 = Color3.fromRGB(240, 240, 255)
			box.PlaceholderText = "Enter your key..."
			box.PlaceholderColor3 = Color3.fromRGB(110, 115, 125)
			box.ClearTextOnFocus = false
			box.Font = Enum.Font.Code
			box.TextSize = 14
			box.Text = ""
			box.Parent = frame
			Instance.new("UICorner", box).CornerRadius = UDim.new(0, 6)

			local btn = Instance.new("TextButton")
			btn.Size = UDim2.new(1, -24, 0, 34)
			btn.Position = UDim2.fromOffset(12, 108)
			btn.BackgroundColor3 = Color3.fromRGB(30, 160, 90)
			btn.TextColor3 = Color3.fromRGB(235, 255, 240)
			btn.Font = Enum.Font.GothamBold
			btn.TextSize = 16
			btn.Text = "ACTIVATE"
			btn.AutoButtonColor = true
			btn.Parent = frame
			Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)

			local msg = label("", 150, 13, Color3.fromRGB(170, 175, 185))

			btn.MouseButton1Click:Connect(function()
				local k = box.Text:gsub("%s", "")
				if #k < 4 then
					msg.TextColor3 = Color3.fromRGB(255, 90, 90)
					msg.Text = "Key too short."
					return
				end
				msg.TextColor3 = Color3.fromRGB(170, 175, 185)
				msg.Text = "Checking..."
				task.spawn(function()
					if valid(k) then
						pcall(function()
							writefile(KEY_FILE, k)
							writefile(KEY_UNTIL_FILE, tostring(os.time() + KEY_TTL))
						end)
						msg.TextColor3 = Color3.fromRGB(120, 235, 160)
						msg.Text = "Accepted! Starting..."
						task.wait(0.4)
						gui:Destroy()
						S.keyGuiUp = false
						S.keyOk = true
						log("key accepted (entered)")
					else
						msg.TextColor3 = Color3.fromRGB(255, 90, 90)
						msg.Text = "Invalid key."
					end
				end)
			end)
		end
		repeat task.wait(0.25) until S.keyOk
	end
	end
end

---------------------------------------------------------------------
-- DECRYPT AND RUN PAYLOAD
do
	local okP, payload = pcall(function()
		return crypt.decrypt(PAYLOAD_CT, PAYLOAD_KEY, PAYLOAD_IV)
	end)
	if not okP or type(payload) ~= "string" or #payload < 100 then
		log("payload decrypt FAILED: " .. tostring(payload))
		return
	end
	local fn, err = loadstring(payload, "=baan-hub-payload")
	if not fn then
		log("payload compile FAILED: " .. tostring(err))
		return
	end
	log("payload decrypted - starting bot (" .. tostring(#payload) .. " bytes)")
	fn()
end
