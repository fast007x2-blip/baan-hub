--// BAAN HUB v9 DISTRIBUTION - key system + AES-256 encrypted payload
local KEY_URL = "https://pastebin.com/raw/LRU4XByY"          -- raw paste url with sha256 lines (fallback mode)
local TOKEN_API = "https://work.ink/_api/v2/token/isValid/"  -- work.ink key system (unique token per user); empty = pastebin mode
local GET_KEY_URL = "https://work.ink/2Tq7/baanhub-key"      -- shown in prompt: where users get a key/token
local HWID_LOCK = false     -- true = each key works on one device only
local KEY_FILE = "baan_hub_key.txt"
local KEY_UNTIL_FILE = "baan_hub_key_until.txt"
local KEY_TTL = 3 * 60 * 60 -- seconds a validated key stays activated (3 hours)
local DEV_KEYS = { "BAANHUB-TEST" }

local PAYLOAD_KEY = "i+MCNy9K1Nlr1uyD5ZoZsKWH820Bh2dhySMuffcYEJY="
local PAYLOAD_IV = "pXieNZYnK9/zvqEGMrnXhQ=="
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
