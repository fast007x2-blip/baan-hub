--// BAAN HUB v9 DISTRIBUTION - key system + AES-256 encrypted payload
local KEY_URL = "https://pastebin.com/raw/LRU4XByY"          -- raw paste url with sha256 lines (fallback mode)
local TOKEN_API = "https://work.ink/_api/v2/token/isValid/"  -- work.ink key system (unique token per user); empty = pastebin mode
local GET_KEY_URL = "https://work.ink/2Tq7/baanhub-key"      -- shown in prompt: where users get a key/token
local HWID_LOCK = false     -- true = each key works on one device only
local KEY_FILE = "baan_hub_key.txt"
local KEY_UNTIL_FILE = "baan_hub_key_until.txt"
local KEY_TTL = 3 * 60 * 60 -- seconds a validated key stays activated (3 hours)
local DEV_KEYS = { "BAANHUB-TEST" }

local PAYLOAD_KEY = "FDInw5hNgs+O51eb+9OyGTXR37SfisuEglSryqsz0KI="
local PAYLOAD_IV = "c6//gVVugFIxt1g6YAY1vQ=="
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
