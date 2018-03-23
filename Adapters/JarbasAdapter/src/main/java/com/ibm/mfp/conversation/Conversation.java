package com.ibm.mfp.conversation;

import org.apache.wink.json4j.JSONObject;

public class Conversation {
    public String authorization;
    public String workspace;


    public Conversation() {
        this.authorization = "";
        this.workspace = "";
    }
}
