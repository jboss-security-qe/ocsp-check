/*
 * JBoss, Home of Professional Open Source.
 * Copyright 2014, Red Hat, Inc., and individual contributors
 * as indicated by the @author tags. See the copyright.txt file in the
 * distribution for a full listing of individual contributors.
 *
 * This is free software; you can redistribute it and/or modify it
 * under the terms of the GNU Lesser General Public License as
 * published by the Free Software Foundation; either version 2.1 of
 * the License, or (at your option) any later version.
 *
 * This software is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with this software; if not, write to the Free
 * Software Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA
 * 02110-1301 USA, or see the FSF site: http://www.fsf.org.
 */

package org.jboss.test.ocsp;

import java.security.KeyStore;
import java.security.Security;
import java.security.cert.CertPath;
import java.security.cert.CertPathValidator;
import java.security.cert.CertStore;
import java.security.cert.CertStoreParameters;
import java.security.cert.Certificate;
import java.security.cert.CertificateFactory;
import java.security.cert.CollectionCertStoreParameters;
import java.security.cert.PKIXParameters;
import java.security.cert.TrustAnchor;
import java.security.cert.X509Certificate;
import java.util.ArrayList;
import java.util.HashSet;
import java.util.List;
import java.util.Set;

import org.jboss.security.auth.certs.X509CertificateVerifier;

/**
 * This class is only a workaround for missing PKIX certificate path validation implementation
 * in the PicketBox. It's reported as a BZ https://bugzilla.redhat.com/show_bug.cgi?id=1080132
 *
 * @author Josef Cacek
 */
public class PKIXCertificateVerifier implements X509CertificateVerifier {

	public boolean verify(X509Certificate cert, String alias,
			KeyStore keyStore, KeyStore trustStore) {
		try {
			List<Certificate> certs = new ArrayList<Certificate>();
			certs.add(cert);
			// init cert path
			CertificateFactory cf = CertificateFactory.getInstance("X509");
			CertPath cp = cf.generateCertPath(certs);

			// load the root CA cert for the OCSP server cert
			X509Certificate rootCACert = (X509Certificate) trustStore
					.getCertificate("ca");

			// init trusted certs
			TrustAnchor ta = new TrustAnchor(rootCACert, null);
			Set<TrustAnchor> trustAnchors = new HashSet<TrustAnchor>();
			trustAnchors.add(ta);

			// init cert store
			Set<Certificate> certSet = new HashSet<Certificate>();
			X509Certificate ocspCert = (X509Certificate) trustStore
					.getCertificate("ocsp");
			certSet.add(ocspCert);
			CertStoreParameters storeParams = new CollectionCertStoreParameters(
					certSet);
			CertStore store = CertStore.getInstance("Collection", storeParams);

			// init PKIX parameters
			PKIXParameters params = null;
			params = new PKIXParameters(trustAnchors);
			params.addCertStore(store);

			Security.setProperty("ocsp.enable", "true");

			// perform validation
			CertPathValidator cpv = CertPathValidator.getInstance("PKIX");
			// PKIXCertPathValidatorResult cpv_result =
			// (PKIXCertPathValidatorResult)
			cpv.validate(cp, params);
			// X509Certificate trustedCert = cpv_result.getTrustAnchor()
			// .getTrustedCert();
		} catch (Exception e) {
			e.printStackTrace();
			return false;
		}
		return true;
	}
}
