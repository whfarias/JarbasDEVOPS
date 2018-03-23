/*
 *    Licensed Materials - Property of IBM
 *    5725-I43 (C) Copyright IBM Corp. 2015, 2016. All Rights Reserved.
 *    US Government Users Restricted Rights - Use, duplication or
 *    disclosure restricted by GSA ADP Schedule Contract with IBM Corp.
 */

package com.ibm.mfp.texttospeech;

import io.swagger.annotations.Api;
import io.swagger.annotations.ApiOperation;
import io.swagger.annotations.ApiParam;
import io.swagger.annotations.ApiResponse;
import io.swagger.annotations.ApiResponses;

import java.util.logging.Logger;

import javax.ws.rs.GET;
import javax.ws.rs.POST;
import javax.ws.rs.Path;
import javax.ws.rs.PathParam;
import javax.ws.rs.Produces;
import javax.ws.rs.Consumes;
import javax.ws.rs.QueryParam;
import javax.ws.rs.core.Context;
import javax.ws.rs.core.MediaType;
import javax.ws.rs.core.Response;
import javax.ws.rs.core.Response.Status;

import org.springframework.web.bind.annotation.RequestBody;
import javax.validation.Valid;

import com.ibm.mfp.adapter.api.ConfigurationAPI;
import com.ibm.mfp.adapter.api.OAuthSecurity;

import org.apache.http.entity.StringEntity;
import org.apache.http.HttpResponse;
import org.apache.http.HttpEntity;
import org.apache.http.client.methods.HttpPost;
import org.apache.http.impl.client.CloseableHttpClient;
import org.apache.http.impl.client.HttpClientBuilder;
import org.apache.commons.io.IOUtils;

import javax.servlet.ServletOutputStream;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpServletRequest;

import java.io.IOException;
import org.xml.sax.SAXException;

import org.jsoup.Jsoup;
import com.google.gson.Gson;

@Api(value = "Text to Speech Adapter")
@Path("/resource")
public class TextToSpeechAdapterResource {
	/*
	 * For more info on JAX-RS see
	 * https://jax-rs-spec.java.net/nonav/2.0-rev-a/apidocs/index.html
	 */

	// Define logger (Standard java.util.Logger)
	static Logger logger = Logger.getLogger(TextToSpeechAdapterResource.class.getName());

	// Inject the MFP configuration API:
	@Context
	ConfigurationAPI configApi;

	/*
	 * Path for method:
	 * "<server address>/mfp/api/adapters/ConversationAdapter/resource/textToSpeech/Synthesize?voice=pt-BR_IsabelaVoice"
	*/

	@ApiOperation(value = "Watson Text to Speech", notes = "Adaptador que realiza as chamadas ao serviço de sintetização de texto do Bluemix.")
	@ApiResponses(value = { @ApiResponse(code = 200, message = "Um arquivo de audio do tipo WAVE (.wav) baseado no texto passado como parâmetro.") })
	@POST
	@Consumes(MediaType.APPLICATION_JSON + ";charset=utf-8")
	@Produces("audio/wav")
	@OAuthSecurity(scope = "RegisteredClient")
	@Path("texttospeech/synthesize")
	public void synthesize(
		@Context HttpServletRequest request,
		@Context HttpServletResponse response,
		@ApiParam(value = "String com o id da voz a ser utilizada para a sintetização.", defaultValue = "pt-BR_IsabelaVoice", required = true) @QueryParam("voice") String voice,
		@RequestBody @Valid @ApiParam(name = "body", value = "JSON contendo as credenciais do Text to Speech e o texto a ser sintetizado.", required = true) Input body)
	throws IOException, IllegalStateException, SAXException {
				String conversationURL = "https://stream.watsonplatform.net/text-to-speech/api/v1/synthesize?voice="+voice;
				HttpPost post = new HttpPost(conversationURL);

				post.setHeader("Authorization", body.authorization);
				post.addHeader("Content-Type", MediaType.APPLICATION_JSON);
				post.setHeader("Accept", "audio/wav");

				body.text = body.text.replace("R$ ", "R$");
				body.text = body.text.replace("r$ ", "R$");
				body.text = Jsoup.parse(body.text, "ASCII").text();

				Gson gson = new Gson();
        String jsonInString = gson.toJson(body);

				System.out.println("LOG jsonInString: \n" + jsonInString);

				HttpEntity entity = new StringEntity(jsonInString, "UTF-8");
    		post.setEntity(entity);

				CloseableHttpClient client = HttpClientBuilder.create().build();
				HttpResponse ttsResponse = client.execute(post);
				System.out.println("Response Code : " + ttsResponse.getStatusLine().getStatusCode());

				ServletOutputStream os = response.getOutputStream();

				response.setStatus(ttsResponse.getStatusLine().getStatusCode());

				IOUtils.copy(ttsResponse.getEntity().getContent(), os);

				os.flush();
				IOUtils.closeQuietly(os);
	}
}
