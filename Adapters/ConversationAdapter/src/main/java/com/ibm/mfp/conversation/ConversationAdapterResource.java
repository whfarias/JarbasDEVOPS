/*
 *    Licensed Materials - Property of IBM
 *    5725-I43 (C) Copyright IBM Corp. 2015, 2016. All Rights Reserved.
 *    US Government Users Restricted Rights - Use, duplication or
 *    disclosure restricted by GSA ADP Schedule Contract with IBM Corp.
 */

package com.ibm.mfp.conversation;

import io.swagger.annotations.Api;
import io.swagger.annotations.ApiOperation;
import io.swagger.annotations.ApiParam;
import io.swagger.annotations.ApiResponse;
import io.swagger.annotations.ApiResponses;

import org.springframework.web.bind.annotation.RequestBody;
import javax.validation.Valid;

import java.util.logging.Logger;

import javax.ws.rs.POST;
import javax.ws.rs.Path;
import javax.ws.rs.PathParam;
import javax.ws.rs.Produces;
import javax.ws.rs.Consumes;
import javax.ws.rs.core.Context;
import javax.ws.rs.core.MediaType;
import javax.ws.rs.core.Response;
import javax.ws.rs.core.Response.Status;

import com.ibm.mfp.adapter.api.ConfigurationAPI;
import com.ibm.mfp.adapter.api.OAuthSecurity;

import org.apache.http.entity.StringEntity;
import org.apache.http.util.EntityUtils;
import org.apache.http.HttpResponse;
import org.apache.http.HttpEntity;
import org.apache.http.client.methods.HttpPost;

import org.apache.http.impl.client.CloseableHttpClient;
import org.apache.http.impl.client.HttpClientBuilder;

import javax.servlet.ServletOutputStream;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpServletRequest;

import java.io.IOException;
import org.xml.sax.SAXException;

import com.google.gson.Gson;

@Api(value = "Conversation Adapter")
@Path("/resource")
public class ConversationAdapterResource {
	// Define logger (Standard java.util.Logger)
	static Logger logger = Logger.getLogger(ConversationAdapterResource.class.getName());

	//Inject the MFP configuration API:
	@Context
	ConfigurationAPI configApi;

	/*
	 * Path for method:
	 * "<server address>/mfp/api/adapters/ConversationAdapter/resource/conversation/{workspace_id}"
	*/

	@ApiOperation(value = "Conversation", notes = "Adaptador responsável por realizar as chamadas ao serviço de conversação do Bluemix.")
	@ApiResponses(value = { @ApiResponse(code = 200, message = "Um objeto JSON contendo todos os dados necessários para uma conversação.") })
	@POST
	@Consumes(MediaType.APPLICATION_JSON)
	@Produces(MediaType.APPLICATION_JSON + ";charset=utf-8")
	@OAuthSecurity(scope = "RegisteredClient")
	@Path("conversation/{workspace_id}")
	public void conversation(
		@Context HttpServletRequest request,
		@Context HttpServletResponse response,
		@ApiParam(value = "Identificador único da Workspace no Conversation que será utilizada.", required = true) @PathParam("workspace_id") String workspaceID,
		@RequestBody @Valid @ApiParam(name = "body", value = "JSON contendo as credenciais do Conversation, a entrada do usuário e o contexto da conversação.", required = true) Body body
	)throws IOException, IllegalStateException, SAXException {
				String conversationURL = "https://gateway.watsonplatform.net/conversation/api/v1/workspaces/" + workspaceID + "/message?version=2017-04-21";
				HttpPost post = new HttpPost(conversationURL);

				post.setHeader("Authorization", body.authorization);
				post.addHeader("Content-Type", MediaType.APPLICATION_JSON);

				Gson gson = new Gson();
				String jsonInString = gson.toJson(body);

				HttpEntity entity = new StringEntity(jsonInString);
        post.setEntity(entity);

				CloseableHttpClient client = HttpClientBuilder.create().build();
				HttpResponse conversationResponse = client.execute(post);

				System.out.println("Response Code : " + conversationResponse.getStatusLine().getStatusCode());

				response.setStatus(conversationResponse.getStatusLine().getStatusCode());

				String json = EntityUtils.toString(conversationResponse.getEntity());
				System.out.println("Response Content : " + json);

				conversationResponse.getEntity().getContent().close();

				ServletOutputStream os = response.getOutputStream();
				os.write(json.getBytes());
				os.flush();
				os.close();
	}
}
