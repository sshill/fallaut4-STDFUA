ScriptName RexfordRomanceEncounterScript Extends Quest

;-- Verified Properties from Fallout4.esm ----------------
Quest Property DialogueGoodneighbor Auto Const
Actor Property MagnoliaREF Auto Const
ObjectReference Property HotelRexfordPlayerBed Auto Const
ObjectReference Property HotelMagnoliaMarkerREF Auto Const
Cell Property GoodneighborHotelRexford Auto Const
Cell Property GoodneighborTheThirdRail Auto Const
ObjectReference Property GoodneighborMagnoliaSingMarker Auto Const
Spell Property LoversEmbracePerkSpell Auto Const
Scene Property MagnoliaGreetScene03 Auto Const
Armor Property ClothesMagnoliaDress Auto Const

;-- Configuration & Toggles -----------------------------
Bool Property EnableMagnolia = True Auto
Bool Property AutoReturnAfterDelay = True Auto
Float Property ReturnDelaySeconds = 180.0 Auto

;-- Internal State Variables ----------------------------
Bool IsPartnerInHotel = False
Actor ActiveHotelPartner = None

;-- Events ---------------------------------------------
Event OnInit()
    RegisterForPlayerSleep()
    Debug.Trace("[RexfordRomance] Mod initialized and registered for PlayerSleep.", 0)
EndEvent

Event OnPlayerSleepStop(Bool abInterrupted, ObjectReference akBed)
    Debug.Trace("[RexfordRomance] OnPlayerSleepStop event fired. Interrupted=" + abInterrupted + ", Bed=" + (akBed as String), 0)
    If !abInterrupted
        Actor player = Game.GetPlayer()
        If player != None
            ; 1. Check if sleeping in Hotel Rexford
            Bool isRexfordBed = False
            If akBed != None
                If akBed == HotelRexfordPlayerBed || akBed.GetParentCell() == GoodneighborHotelRexford
                    isRexfordBed = True
                EndIf
            ElseIf player.GetParentCell() == GoodneighborHotelRexford
                isRexfordBed = True
            EndIf
            Debug.Trace("[RexfordRomance] Bed check: isRexfordBed=" + isRexfordBed + ", playerCell=" + (player.GetParentCell() as String), 0)

            If isRexfordBed
                ; 2. CHECK IF PLAYER IS WITH AN ACTIVE ROMANTIC COMPANION (Piper, Cait, Curie, Danse, etc.)
                ; If player is already with a romanced partner, Magnolia MUST NOT appear!
                Bool hasActiveRomanticCompanion = False
                FollowersScript fs = FollowersScript.GetScript()
                If fs != None
                    Actor romanticComp = fs.GetNearbyInfatuatedRomanticCompanion()
                    If romanticComp != None
                        hasActiveRomanticCompanion = True
                        Debug.Trace("[RexfordRomance] Romantic companion detected nearby: " + (romanticComp as String), 0)
                    Else
                        companionactorscript curComp = fs.Companion.GetActorReference() as companionactorscript
                        If curComp != None
                            Debug.Trace("[RexfordRomance] Active companion: " + (curComp as String) + ", IsRomantic=" + curComp.IsRomantic() + ", IsInfatuated=" + curComp.IsInfatuated(), 0)
                            If curComp.IsRomantic() && curComp.IsInfatuated()
                                If player.GetDistance(curComp as ObjectReference) < 2500.0 || curComp.GetParentCell() == GoodneighborHotelRexford
                                    hasActiveRomanticCompanion = True
                                    Debug.Trace("[RexfordRomance] Active companion is romantic & near player in Hotel Rexford.", 0)
                                EndIf
                            EndIf
                        EndIf
                    EndIf
                EndIf

                If hasActiveRomanticCompanion
                    Debug.Trace("[RexfordRomance] Active romantic companion present in Hotel Rexford. Magnolia suppressed.", 0)
                    Return
                EndIf

                ; 3. Check Romance Status with Magnolia from DialogueGoodneighbor
                Bool magnoliaRomanced = False
                DialogueGoodneighborScript dg = DialogueGoodneighbor as DialogueGoodneighborScript
                If dg != None
                    Debug.Trace("[RexfordRomance] DialogueGoodneighbor status: DateComplete=" + dg.DateComplete + ", MagnoliaFlirt=" + dg.MagnoliaFlirt, 0)
                    If dg.DateComplete == 1 || dg.MagnoliaFlirt >= 3
                        magnoliaRomanced = True
                    EndIf
                EndIf

                ; 4. Pick Active Partner (Magnolia)
                Actor chosenPartner = None
                If EnableMagnolia && magnoliaRomanced && MagnoliaREF != None && !MagnoliaREF.IsDead()
                    chosenPartner = MagnoliaREF
                    Debug.Trace("[RexfordRomance] Magnolia selected as active partner.", 0)
                EndIf

                If chosenPartner != None
                    ; 5. Seamless Transition & Dynamic Bed Scene
                    ; Fade out screen momentarily while arranging partner in bed
                    Game.FadeOutGame(True, True, 0.1, 2.0, True)
                    Utility.Wait(1.5)

                    ; Position partner on bed & wait for 3D load before snap
                    If HotelRexfordPlayerBed != None
                        chosenPartner.MoveTo(HotelRexfordPlayerBed, 20.0, 20.0, 0.0, True)
                        Int wait3D = 0
                        While !chosenPartner.Is3DLoaded() && wait3D < 15
                            Utility.Wait(0.1)
                            wait3D += 1
                        EndWhile
                        Bool snapSuccess = chosenPartner.SnapIntoInteraction(HotelRexfordPlayerBed)
                        Debug.Trace("[RexfordRomance] Bed snap interaction result: " + snapSuccess, 0)
                        chosenPartner.SetRestrained(True)
                    Else
                        chosenPartner.MoveTo(HotelMagnoliaMarkerREF, 0.0, 0.0, 0.0, True)
                        chosenPartner.SetRestrained(True)
                    EndIf

                    If ClothesMagnoliaDress != None
                        If chosenPartner.GetItemCount(ClothesMagnoliaDress) == 0
                            chosenPartner.AddItem(ClothesMagnoliaDress, 1, True)
                        EndIf
                        chosenPartner.UnequipItem(ClothesMagnoliaDress, False, True)
                    EndIf
                    ActiveHotelPartner = chosenPartner
                    IsPartnerInHotel = True
                    Debug.Trace("[RexfordRomance] Partner " + (chosenPartner as String) + " positioned in bed in sleep state.", 0)

                    ; Grant Lover's Embrace perk/spell
                    If LoversEmbracePerkSpell != None
                        LoversEmbracePerkSpell.Cast(player as ObjectReference, player as ObjectReference)
                        Debug.Trace("[RexfordRomance] Lover's Embrace perk spell cast on player.", 0)
                    EndIf

                    Debug.Notification("Готель «Рексфорд»: Затишна ніч разом. Отримано «Обійми коханця».")

                    ; Fade back in: player and partner are in bed
                    Game.FadeOutGame(False, True, 0.0, 1.5, False)

                    ; 6. Morning Wake-Up & Dressing Phase
                    ; Wait for player to fully finish standing-up animation (~3.5s)
                    Utility.Wait(3.5)
                    chosenPartner.SetRestrained(False)

                    ; Magnolia stands up, dresses back into singer concert dress
                    If ClothesMagnoliaDress != None
                        If chosenPartner.GetItemCount(ClothesMagnoliaDress) == 0
                            chosenPartner.AddItem(ClothesMagnoliaDress, 1, True)
                        EndIf
                        chosenPartner.EquipItem(ClothesMagnoliaDress, False, True)
                    EndIf
                    chosenPartner.SetLookAt(player as ObjectReference, True)
                    chosenPartner.EvaluatePackage(False)

                    If MagnoliaGreetScene03 != None
                        If MagnoliaGreetScene03.IsPlaying()
                            MagnoliaGreetScene03.Stop()
                        EndIf
                        MagnoliaGreetScene03.ForceStart()
                        Debug.Trace("[RexfordRomance] MagnoliaGreetScene03 ForceStart called.", 0)
                    EndIf

                    ; 7. Start return timer if enabled
                    If AutoReturnAfterDelay && ReturnDelaySeconds > 0.0
                        StartTimer(ReturnDelaySeconds, 1001)
                        Debug.Trace("[RexfordRomance] Return timer started: " + ReturnDelaySeconds + " seconds.", 0)
                    EndIf
                Else
                    Debug.Trace("[RexfordRomance] No partner qualified for spawn (Magnolia romanced=" + magnoliaRomanced + ").", 0)
                EndIf
            EndIf
        EndIf
    EndIf
EndEvent

Event OnTimer(Int aiTimerID)
    If aiTimerID == 1001
        Debug.Trace("[RexfordRomance] Timer 1001 fired. Checking partner return.", 0)
        ResetPartnerLocation()
    EndIf
EndEvent

Function ResetPartnerLocation()
    If IsPartnerInHotel && ActiveHotelPartner != None
        Actor player = Game.GetPlayer()
        If player.GetParentCell() != GoodneighborHotelRexford || player.GetDistance(ActiveHotelPartner as ObjectReference) > 1500.0
            ActiveHotelPartner.ClearLookAt()
            ActiveHotelPartner.SetRestrained(False)
            ; Safeguard: Ensure concert dress is restored before returning to schedule
            If ClothesMagnoliaDress != None
                If ActiveHotelPartner.GetItemCount(ClothesMagnoliaDress) == 0
                    ActiveHotelPartner.AddItem(ClothesMagnoliaDress, 1, True)
                EndIf
                ActiveHotelPartner.EquipItem(ClothesMagnoliaDress, False, True)
            EndIf
            If ActiveHotelPartner == MagnoliaREF && GoodneighborMagnoliaSingMarker != None
                ActiveHotelPartner.MoveTo(GoodneighborMagnoliaSingMarker, 0.0, 0.0, 0.0, True)
                ActiveHotelPartner.EvaluatePackage(False)
            EndIf
            Debug.Trace("[RexfordRomance] Partner " + (ActiveHotelPartner as String) + " returned to standard schedule.", 0)
            IsPartnerInHotel = False
            ActiveHotelPartner = None
        Else
            Debug.Trace("[RexfordRomance] Player still close to partner in Hotel Rexford. Rescheduling return timer (60s).", 0)
            StartTimer(60.0, 1001)
        EndIf
    EndIf
EndFunction
