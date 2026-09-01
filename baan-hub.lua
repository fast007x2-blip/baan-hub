--// BAAN HUB v9 DISTRIBUTION - key system + AES-256 encrypted payload
local KEY_URL = "https://pastebin.com/raw/LRU4XByY"          -- raw paste url with sha256 lines (fallback mode)
local TOKEN_API = "https://work.ink/_api/v2/token/isValid/"  -- work.ink key system (unique token per user); empty = pastebin mode
local GET_KEY_URL = "https://work.ink/2Tq7/baanhub-key"      -- shown in prompt: where users get a key/token
local HWID_LOCK = false     -- true = each key works on one device only
local KEY_FILE = "baan_hub_key.txt"
local KEY_UNTIL_FILE = "baan_hub_key_until.txt"
local KEY_TTL = 3 * 60 * 60 -- seconds a validated key stays activated (3 hours)
local DEV_KEYS = { "BAANHUB-TEST" }

local PAYLOAD_KEY = "GbKPLW7eW7adu2KRhnX42dWWmA5KQBs9v+p9SNZOU20="
local PAYLOAD_IV = "xrVNcTogxn18NrrYWwCm7g=="
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
