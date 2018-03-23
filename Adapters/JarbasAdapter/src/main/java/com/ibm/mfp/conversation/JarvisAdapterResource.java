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

@Api(value = "Jarvis Adapter")
@Path("/resource")
public class JarvisAdapterResource {
	// Define logger (Standard java.util.Logger)
	static Logger logger = Logger.getLogger(JarvisAdapterResource.class.getName());

	//Inject the MFP configuration API:
	@Context
	ConfigurationAPI configApi;

	/*
	 * Path for method:
	 * "<server address>/mfp/api/adapters/JarvisAdapter/resource/conversation/{workspace_id}"
	*/

	@ApiOperation(value = "User Conversation", notes = "Chamada feita para utilizar o conversation do usuario. ")
	@ApiResponses(value = { @ApiResponse(code = 200, message = "Um objeto JSON contendo todos os dados necessários para encontrar uma loja perto do usuario") })
	@POST
	@Consumes(MediaType.APPLICATION_JSON + ";charset=utf-8")
	@Produces(MediaType.APPLICATION_JSON + ";charset=utf-8")
	@Path("userConversation")
	public void conversation(
		@Context HttpServletRequest request,
		@Context HttpServletResponse response,
	 	@RequestBody @Valid @ApiParam(name = "body", value = "JSON contendo a entrada do usuário.", required = true) Body body
	)throws IOException, IllegalStateException, SAXException {
				String fixTextUrl = "https://genericconversation-orchestrator.mybluemix.net/conversationUser";
				HttpPost post = new HttpPost(fixTextUrl);

				post.addHeader("Content-Type", MediaType.APPLICATION_JSON);

				Gson gson = new Gson();
				String jsonInString = gson.toJson(body);

				HttpEntity entity = new StringEntity(jsonInString, "UTF-8");
       			post.setEntity(entity);

				CloseableHttpClient client = HttpClientBuilder.create().build();
				HttpResponse storesResponse = client.execute(post);

				System.out.println("Response Code : " + storesResponse.getStatusLine().getStatusCode());

				response.setStatus(storesResponse.getStatusLine().getStatusCode());

				String json = EntityUtils.toString(storesResponse.getEntity());
				System.out.println("Response Content : " + json);

				storesResponse.getEntity().getContent().close();

				ServletOutputStream os = response.getOutputStream();
				os.write(json.getBytes());
				os.flush();
				os.close();
	}

	@ApiOperation(value = "Jarbas Conversation", notes = "Chamada feita para utilizar o conversation Jarbas. ")
	@ApiResponses(value = { @ApiResponse(code = 200, message = "Um objeto JSON contendo todos os dados necessários para encontrar uma loja perto do usuario") })
	@POST
	@Consumes(MediaType.APPLICATION_JSON + ";charset=utf-8")
	@Produces(MediaType.APPLICATION_JSON + ";charset=utf-8")
	@Path("jarbasConversation")
	public void conversationJarbas(
		@Context HttpServletRequest request,
		@Context HttpServletResponse response,
	 	@RequestBody @Valid @ApiParam(name = "body", value = "JSON contendo a entrada do usuário.", required = true) BodyJarbas body
	)throws IOException, IllegalStateException, SAXException {
				String fixTextUrl = "https://genericconversation-orchestrator.mybluemix.net/jarbasConversation";
				HttpPost post = new HttpPost(fixTextUrl);

				post.addHeader("Content-Type", MediaType.APPLICATION_JSON);

				Gson gson = new Gson();
				String jsonInString = gson.toJson(body);
				

				HttpEntity entity = new StringEntity(jsonInString, "UTF-8");
       			post.setEntity(entity);

				CloseableHttpClient client = HttpClientBuilder.create().build();
				HttpResponse storesResponse = client.execute(post);

				System.out.println("Response Code : " + storesResponse.getStatusLine().getStatusCode());

				response.setStatus(storesResponse.getStatusLine().getStatusCode());

				// String json = EntityUtils.toString(storesResponse.getEntity(),"UTF-8");
				String json = EntityUtils.toString(storesResponse.getEntity());

				System.out.println("Response Content : " + json);

				storesResponse.getEntity().getContent().close();

				ServletOutputStream os = response.getOutputStream();
				os.write(json.getBytes());
				os.flush();
				os.close();
	}
}
