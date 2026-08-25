--// BAAN HUB v9 DISTRIBUTION - key system + AES-256 encrypted payload
local KEY_URL = "https://pastebin.com/raw/LRU4XByY"          -- raw paste url with sha256 lines (fallback mode)
local TOKEN_API = "https://work.ink/_api/v2/token/isValid/"  -- work.ink key system (unique token per user); empty = pastebin mode
local GET_KEY_URL = "https://work.ink/2Tq7/baanhub-key"      -- shown in prompt: where users get a key/token
local HWID_LOCK = false     -- true = each key works on one device only
local KEY_FILE = "baan_hub_key.txt"
local KEY_UNTIL_FILE = "baan_hub_key_until.txt"
local KEY_TTL = 3 * 60 * 60 -- seconds a validated key stays activated (3 hours)
local DEV_KEYS = { "BAANHUB-TEST" }

local PAYLOAD_KEY = "l3Lh9Fntw2IuvYps7Zw1YDbIHxbeZFZDcHhkJjPFA4A="
local PAYLOAD_IV = "0S+StSIggJ8RRrD3jcavNQ=="
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
