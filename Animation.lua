-- ANIMATION MODULE --

local animating = ClassicNumbersEx.animating
local recycleFontString = ClassicNumbersEx.recycleFontString

-- ANIMATION --
local function powSizing(elapsed, duration, start, middle, finish)
	local size = finish
	if elapsed < duration then
		if elapsed / duration < 0.1 then
			size = LibStub("LibEasing-1.0").OutCirc(elapsed, start, middle - start, duration / 2)
		else
			size = LibStub("LibEasing-1.0").InCirc(elapsed - elapsed / 2, middle, finish - middle, duration / 2)
		end
	end
	return size
end

local function AnimationOnUpdate()
	local animationDuration = 1
	if next(animating) then
		for fontString, _ in pairs(animating) do
			local elapsed = GetTime() - fontString.animatingStartTime
			if fontString.pow then
				animationDuration = fontString.critAnimationDuration
			else
				animationDuration = fontString.nonCritAnimationDuration
			end
			if elapsed > animationDuration then
				-- the animation is over
				recycleFontString(fontString)
			else
				local isTarget = false
				if fontString.unit then
					isTarget = UnitIsUnit(fontString.unit, "target")
				else
					fontString.unit = "player"
				end

				local alpha = 0
				if elapsed / animationDuration < 0.3 then
					if fontString.pow then
						alpha = LibStub("LibEasing-1.0").OutQuint(
							elapsed,
							0,
							fontString.critsAlpha,
							animationDuration * 0.3
						)
					else
						alpha = LibStub("LibEasing-1.0").OutQuint(
							elapsed,
							0,
							fontString.normalHitsAlpha,
							animationDuration * 0.3
						)
					end
				else
					if fontString.pow then
						alpha = LibStub("LibEasing-1.0").InExpo(
							elapsed,
							fontString.critsAlpha,
							-fontString.critsAlpha,
							animationDuration
						)
					else
						alpha = LibStub("LibEasing-1.0").InExpo(
							elapsed,
							fontString.normalHitsAlpha,
							-fontString.normalHitsAlpha,
							animationDuration
						)
					end
				end

				fontString:SetAlpha(alpha)

				-- crit size animation
				if fontString.pow then
					if elapsed < 0.2 then
						local size = powSizing(
							elapsed,
							0.2,
							fontString.startHeight / 2,
							fontString.startHeight * 2,
							fontString.startHeight
						)

						fontString:SetTextHeight(size)
						fontString.fontHeight = size
					else
						local size = powSizing(
							elapsed,
							0.2,
							fontString.startHeight / 2,
							fontString.startHeight * 2,
							fontString.startHeight
						)

						fontString:SetTextHeight(size)
						fontString:SetText(fontString.text)
					end
				end

				local newestCrit = GetNewestCrit(fontString.anchorFrame)
				if newestCrit ~= nil and fontString.isCritNumber[fontString.anchorFrame] ~= nil then
					-- handle crit position
					if fontString.isCritNumber[fontString.anchorFrame] == 1 then
						fontString.offsetX = 0
						fontString.offsetY = -40
						if fontString.maxCritNumbersPerTarget < 1 then
							fontString:SetAlpha(0)
						end
					elseif fontString.isCritNumber[fontString.anchorFrame] == 2 then
						fontString.offsetX = newestCrit.textWidth + newestCrit.fontHeight + 9
						fontString.offsetY = -40
						if fontString.maxCritNumbersPerTarget < 2 then
							fontString:SetAlpha(0)
						end
					elseif fontString.isCritNumber[fontString.anchorFrame] == 3 then
						fontString.offsetX = -newestCrit.textWidth - newestCrit.fontHeight - 9
						fontString.offsetY = -40
						if fontString.maxCritNumbersPerTarget < 3 then
							fontString:SetAlpha(0)
						end
					elseif fontString.isCritNumber[fontString.anchorFrame] == 4 then
						fontString.offsetX = 0
						fontString.offsetY = newestCrit.offsetY + newestCrit.fontHeight + 9
						if fontString.maxCritNumbersPerTarget < 4 then
							fontString:SetAlpha(0)
						end
					elseif fontString.isCritNumber[fontString.anchorFrame] == 5 then
						fontString.offsetX = 0
						fontString.offsetY = newestCrit.offsetY - newestCrit.fontHeight - 9
						if fontString.maxCritNumbersPerTarget < 5 then
							fontString:SetAlpha(0)
						end
					elseif fontString.isCritNumber[fontString.anchorFrame] > 5 then
						fontString:SetAlpha(0)
					end
				end

				-- handle non crit
				if not fontString.pow then
					if not fontString.hasBeenPlaced then
						fontString.offsetY = 20
					end

					-- disappear if lots of crits
					if GetFourthCrit(fontString.anchorFrame) ~= nil and fontString.hideNonCritsIfBigCritChain then
						fontString:SetAlpha(0)
					end

					-- non crit position
					local closestFontStringY = GetClosestDamageNumberYValueFrom(fontString)

					if closestFontStringY ~= nil and elapsed < 0.1 then
						local differenceFromClosest = math.abs(fontString.offsetY - closestFontStringY.offsetY)
						if differenceFromClosest < 30 then
							if fontString.offsetX == 0 and closestFontStringY.offsetX == 0 then
								fontString.offsetX = 80
							elseif fontString.offsetX == 80 and closestFontStringY.offsetX == 80 then
								fontString.offsetX = -80
							end
							if
								fontString.offsetY2 ~= 0
								and fontString.offsetX == -80
								and closestFontStringY.offsetX == -80
							then
								closestFontStringY.offsetY2 = LibStub("LibEasing-1.0").OutQuad(
									1.1,
									20,
									fontString.scrollDistance,
									animationDuration
								)
								closestFontStringY.offsetX = math.random(-1, 1) * 80
							end
						end
					end
					if fontString.offsetY2 ~= nil then
						fontString.offsetY = LibStub("LibEasing-1.0").OutQuad(
							elapsed,
							20,
							fontString.scrollDistance,
							animationDuration
						) + fontString.offsetY2
					else
						fontString.offsetY =
							LibStub("LibEasing-1.0").OutQuad(elapsed, 20, fontString.scrollDistance, animationDuration)
					end
				end

				if fontString.anchorFrame and fontString.anchorFrame:IsShown() then
					if fontString.pow then
						fontString:SetPoint(
							"CENTER",
							fontString.anchorFrame,
							"CENTER",
							fontString.offsetX + fontString.critsOffsetX,
							fontString.offsetY + fontString.critsOffsetY
						)
					else
						fontString:SetPoint(
							"CENTER",
							fontString.anchorFrame,
							"CENTER",
							fontString.offsetX + fontString.nonCritsOffsetX,
							fontString.offsetY + fontString.nonCritsOffsetY
						)
					end
					fontString.hasBeenPlaced = true
				else
					recycleFontString(fontString)
				end
			end
		end
	else
		-- nothing in the animation list, so just kill the onupdate
		ClassicNumbersEx.frame:SetScript("OnUpdate", nil)
	end
end

function ClassicNumbersEx:Animate(fontString, anchorFrame, animation)
	fontString.animatingStartTime = GetTime()
	fontString.anchorFrame = anchorFrame == player and UIParent or anchorFrame

	if (fontString.pow and self.db.global.critSize > 0) or (not fontString.pow and self.db.global.size > 0) then
		animating[fontString] = true
	end

	if fontString.pow then
		fontString.isCritNumber[fontString.anchorFrame] = 0
		OffsetCritIndexes(fontString.anchorFrame, 1, false)
	end

	-- start onupdate if it's not already running
	if ClassicNumbersEx.frame:GetScript("OnUpdate") == nil then
		ClassicNumbersEx.frame:SetScript("OnUpdate", AnimationOnUpdate)
	end
end
