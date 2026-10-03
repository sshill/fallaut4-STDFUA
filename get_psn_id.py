import urllib.request, urllib.parse, json, base64, sys

def get_account_id(code):
    CLIENT_ID = "ba495a24-818c-472b-b12d-ff231c1b5745"
    CLIENT_SECRET = "mvaiZkRsAsI1IBkY"
    TOKEN_URL = "https://auth.api.sonyentertainmentnetwork.com/2.0/oauth/token"
    SCOPE = "psn:clientapp referenceDataService:countryConfig.read pushNotification:webSocket.desktop.connect sessionManager:remotePlaySession.system.update"
    REDIRECT_URI = "https://remoteplay.dl.playstation.net/remoteplay/redirect"

    auth_str = f"{CLIENT_ID}:{CLIENT_SECRET}"
    auth_b64 = base64.b64encode(auth_str.encode()).decode()

    data = urllib.parse.urlencode({
        "grant_type": "authorization_code",
        "code": code,
        "scope": SCOPE,
        "redirect_uri": REDIRECT_URI
    }).encode("ascii")

    req = urllib.request.Request(TOKEN_URL, data=data, headers={
        "Authorization": f"Basic {auth_b64}",
        "Content-Type": "application/x-www-form-urlencoded"
    })

    with urllib.request.urlopen(req) as resp:
        token_data = json.loads(resp.read().decode())
        token = token_data["access_token"]
        
        req2 = urllib.request.Request(f"{TOKEN_URL}/{urllib.parse.quote(token)}", headers={
            "Authorization": f"Basic {auth_b64}",
            "Accept": "application/json"
        })
        with urllib.request.urlopen(req2) as resp2:
            account_info = json.loads(resp2.read().decode())
            user_id = int(account_info["user_id"])
            user_id_b64 = base64.b64encode(user_id.to_bytes(8, "little")).decode()
            return user_id, user_id_b64

if __name__ == "__main__":
    if len(sys.argv) > 1:
        raw = sys.argv[1]
        if "code=" in raw:
            import urllib.parse
            parsed = urllib.parse.urlparse(raw)
            qs = urllib.parse.parse_qs(parsed.query)
            code = qs["code"][0]
        else:
            code = raw
        try:
            uid, b64 = get_account_id(code)
            print("USER_ID:", uid)
            print("BASE64_ACCOUNT_ID:", b64)
        except Exception as e:
            print("Error:", e)
