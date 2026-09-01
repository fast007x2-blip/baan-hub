--// BAAN HUB v9 DISTRIBUTION - key system + AES-256 encrypted payload
local KEY_URL = "https://pastebin.com/raw/LRU4XByY"          -- raw paste url with sha256 lines (fallback mode)
local TOKEN_API = "https://work.ink/_api/v2/token/isValid/"  -- work.ink key system (unique token per user); empty = pastebin mode
local GET_KEY_URL = "https://work.ink/2Tq7/baanhub-key"      -- shown in prompt: where users get a key/token
local HWID_LOCK = false     -- true = each key works on one device only
local KEY_FILE = "baan_hub_key.txt"
local KEY_UNTIL_FILE = "baan_hub_key_until.txt"
local KEY_TTL = 3 * 60 * 60 -- seconds a validated key stays activated (3 hours)
local DEV_KEYS = { "BAANHUB-TEST" }

local PAYLOAD_KEY = "i3nKMl1fFsHVuJ9VVPINxOth4YJxRHolb7v76KLxpRg="
local PAYLOAD_IV = "vGMZFGQbApYeERGDjATCYg=="
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
