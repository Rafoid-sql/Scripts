expdp dbaass@dbass network_link=REMOTE_PROD FLASHBACK_SCN=356565754608 DUMPFILE=EXP_PROD_LOB.dmp directory=DATAPUMP_TESTE SCHEMAS=DBAASS,POS_EAD,NFSE_NEAD,NFSE_EAD,NFSE_POS,OPENFIRE,AVA,OPENFIRENET,OLIMPOINTEGRA,NFSE_NDD directory=DATAPUMP_TESTE REMAP_DATA=DBAASS.ADMINISTRACAO_SQL_DOWNLOAD.ADSD_ARQU:pkg_null_blob.sf_null_blob,DBAASS.ADMINISTRACAO_SQL_RESULTADO.ADSR_ARQU:pkg_null_blob.sf_null_blob,DBAASS.ALBUM_FOTO.ALFO_FOTO:pkg_null_blob.sf_null_blob,DBAASS.ALUNO.ALUN_ACOM:pkg_null_blob.sf_null_blob,DBAASS.ALUNO_SEMESTRE_DOCUMENTO.ASDO_ARQU:pkg_null_blob.sf_null_blob,DBAASS.AMBIENTE_PESQUISA.AMPE_ARQU:pkg_null_blob.sf_null_blob,DBAASS.ARQUIVO_DOWNLOAD.ARDO_ARQU:pkg_null_blob.sf_null_blob,DBAASS.ARQUIVO_TEMP.ARQT_ARQU:pkg_null_blob.sf_null_blob,DBAASS.ATENDIMENTO_ACOMP_ANEXO.ATAA_ARQU:pkg_null_blob.sf_null_blob,DBAASS.ATIVIDADE_COMPLEMENTAR.ATIV_ARQU:pkg_null_blob.sf_null_blob,DBAASS.AVALIACAO.AVAL_ARQU:pkg_null_blob.sf_null_blob,DBAASS.AVALIACAO_TURMA_ATA.AVAT_IMAG:pkg_null_blob.sf_null_blob,DBAASS.AVALIACAO_TURMA_DOCUMENTO.ATDO_ARQU:pkg_null_blob.sf_null_blob,DBAASS.AVISO.AVIS_IMAG:pkg_null_blob.sf_null_blob,DBAASS.BANCO.BANC_LOGO:pkg_null_blob.sf_null_blob,DBAASS.BANCO_EXERCICIO.BAEX_IMAG:pkg_null_blob.sf_null_blob,DBAASS.BANCO_MATERIAL.BAMA_ARQU:pkg_null_blob.sf_null_blob,DBAASS.BANCO_QUESTAO.BAQU_ARQU:pkg_null_blob.sf_null_blob,DBAASS.BANCO_QUESTAO.BAQU_IMAG:pkg_null_blob.sf_null_blob,DBAASS.BANCO_QUESTAO.BAQU_RIMG:pkg_null_blob.sf_null_blob,DBAASS.BANCO_QUESTAO_ANEXO.BAAN_IMAG:pkg_null_blob.sf_null_blob,DBAASS.CADERNO_ESTUDO_VIRTUAL.CDES_ARQU:pkg_null_blob.sf_null_blob,DBAASS.CNAB_COBR_TERC.CNCT_ARQU:pkg_null_blob.sf_null_blob,DBAASS.CONFIGURACAO_ELEMENTOS_X.CFGE_PWHE:pkg_null_blob.sf_null_blob,DBAASS.CONFIGURACAO_ELEMENTOS_X.CFGE_WHER:pkg_null_blob.sf_null_blob,DBAASS.CONTATO_ANEXO.COAN_ARQU:pkg_null_blob.sf_null_blob,DBAASS.CONTEUDO_MENU.CTME_SQL:pkg_null_blob.sf_null_blob,DBAASS.CURSO.CURS_CARI:pkg_null_blob.sf_null_blob,DBAASS.CURSO.CURS_DIPL:pkg_null_blob.sf_null_blob,DBAASS.CURSO.CURS_IMAG:pkg_null_blob.sf_null_blob,DBAASS.CURSO.CURS_LOGO:pkg_null_blob.sf_null_blob,DBAASS.DJ.BMP:pkg_null_blob.sf_null_blob,DBAASS.ENADE_ALUNO_EXCECAO.EAEX_ARQU:pkg_null_blob.sf_null_blob,DBAASS.ENADE_ARQUIVO_EXPORTACAO.EARE_RARQ:pkg_null_blob.sf_null_blob,DBAASS.ENADE_ARQUIVO_MEC.EAME_ARQU:pkg_null_blob.sf_null_blob,DBAASS.ESELECAO_POLO_ARQUIVO.EPAR_ARQU:pkg_null_blob.sf_null_blob,DBAASS.ESELECAO_QUESTAO.EQUE_IMAG:pkg_null_blob.sf_null_blob,DBAASS.ESELECAO_REDACAO_DOCUMENTO.ESRD_ARQU:pkg_null_blob.sf_null_blob,DBAASS.ESELECAO_SEMESTRE_ARQU.ESAR_ARQU:pkg_null_blob.sf_null_blob,DBAASS.ESTAGIO_ALUNO_DOCUMENTO.EDOC_ARQU:pkg_null_blob.sf_null_blob,DBAASS.ESTAGIO_CONVENIO.ESCO_ARQU:pkg_null_blob.sf_null_blob,DBAASS.ESTRUTURA_TEMPLATE.ESTT_CODF:pkg_null_blob.sf_null_blob,DBAASS.EVENTO.EVEN_CERT:pkg_null_blob.sf_null_blob,DBAASS.EVENTO_SITE.EVSI_IMAG:pkg_null_blob.sf_null_blob,DBAASS.EXAME_SELECAO_FOLHA_RESPOSTA.EXFR_ARQU:pkg_null_blob.sf_null_blob,DBAASS.EXERC_PROVA_ONLINE.EXPR_ARQU:pkg_null_blob.sf_null_blob,DBAASS.EXERC_PROVA_QUEST.EXQU_IMAG:pkg_null_blob.sf_null_blob,DBAASS.EXPORTA_DADO.EXPD_ARQU:pkg_null_blob.sf_null_blob,DBAASS.FIQUE_LIGADO.FIQU_IMAG:pkg_null_blob.sf_null_blob,DBAASS.FORMANDO.FORM_PROC:pkg_null_blob.sf_null_blob,DBAASS.FORMANDO_PROCESSO_DOCUMENTO.FPDO_IMAG:pkg_null_blob.sf_null_blob,DBAASS.FORMANDO_TURMA.FOTU_ARQU:pkg_null_blob.sf_null_blob,DBAASS.IMPRESSAO_DOCUMENTO.IMDO_ARQU:pkg_null_blob.sf_null_blob,DBAASS.INTER_ANEXO.IANE_IMAG:pkg_null_blob.sf_null_blob,DBAASS.INTER_QUESTAO.IQUE_IMAG:pkg_null_blob.sf_null_blob,DBAASS.INTER_QUESTAO_SELE.IQSE_IMAG:pkg_null_blob.sf_null_blob,DBAASS.JOIA_TRABALHO.JOTR_ARQU:pkg_null_blob.sf_null_blob,DBAASS.LOG_AVALIACAO.AVAL_ARQU:pkg_null_blob.sf_null_blob,DBAASS.LOG_PESSOA_DOCUMENTO.PDOC_IMAG:pkg_null_blob.sf_null_blob,DBAASS.MAAV_DISCIPLINA_ANEXO.MAAX_ARQU:pkg_null_blob.sf_null_blob,DBAASS.MATERIAL_ALUNO_BANCO.MABA_ARQU:pkg_null_blob.sf_null_blob,DBAASS.MATERIAL_APOIO.MAAP_ARQU:pkg_null_blob.sf_null_blob,DBAASS.MATERIAL_IDENTIFICACAO.MAID_ARQU:pkg_null_blob.sf_null_blob,DBAASS.MATERIAL_SITE.MASI_ARQU:pkg_null_blob.sf_null_blob,DBAASS.MA_ENQUETE.ENQU_ARQU:pkg_null_blob.sf_null_blob,DBAASS.MA_FORUM.FORU_ARQU:pkg_null_blob.sf_null_blob,DBAASS.MA_MATERIAL_APOIO.MAAP_ARQU:pkg_null_blob.sf_null_blob,DBAASS.NOTICIA_SITE.NOSI_IMAG:pkg_null_blob.sf_null_blob,DBAASS.OBJETO_APRENDIZAGEM.OBAP_ARQU:pkg_null_blob.sf_null_blob,DBAASS.PARAMETRO.FOTO_OFF:pkg_null_blob.sf_null_blob,DBAASS.PCSF_CPU_USAGE_SUMMARY.NODES:pkg_null_blob.sf_null_blob,DBAASS.PCSF_DOMAIN.CONFIGURATION:pkg_null_blob.sf_null_blob,DBAASS.PCSF_DOMAIN_GROUP_PRIVILEGE.METADATA:pkg_null_blob.sf_null_blob,DBAASS.PCSF_DOMAIN_USER_PRIVILEGE.METADATA:pkg_null_blob.sf_null_blob,DBAASS.PCSF_GROUP.METADATA:pkg_null_blob.sf_null_blob,DBAASS.PCSF_REPO_USAGE_SUMMARY.REPOS:pkg_null_blob.sf_null_blob,DBAASS.PCSF_ROLE.METADATA:pkg_null_blob.sf_null_blob,DBAASS.PCSF_USER.METADATA:pkg_null_blob.sf_null_blob,DBAASS.PESSOA_DOCUMENTO.PDOC_IMAG:pkg_null_blob.sf_null_blob,DBAASS.PESSOA_DOCUMENTO_DIVERSO.PDOD_ARQU:pkg_null_blob.sf_null_blob,DBAASS.PESSOA_DOCUMENTO_SEME.PDOS_ARQU:pkg_null_blob.sf_null_blob,DBAASS.PESSOA_DOCUMENTO_SEME_TEMP.PDST_ARQU:pkg_null_blob.sf_null_blob,DBAASS.PESSOA_DOCUMENTO_TEMP.PDOT_IMAG:pkg_null_blob.sf_null_blob,DBAASS.PRODUCAO_ACADEMICA.PRAC_ARQU:pkg_null_blob.sf_null_blob,DBAASS.PROVA.PROP_ARDI:pkg_null_blob.sf_null_blob,DBAASS.PROVA.PROP_ARQU:pkg_null_blob.sf_null_blob,DBAASS.PROVA_ALUNO_RESPOSTA.PARE_ARQU:pkg_null_blob.sf_null_blob,DBAASS.PROVA_ALUNO_RESPOSTA_X.PARE_ARQU:pkg_null_blob.sf_null_blob,DBAASS.PROVA_ANEXO.PROA_IMAG:pkg_null_blob.sf_null_blob,DBAASS.PROVA_QUESTAO.PRPQ_ARQR:pkg_null_blob.sf_null_blob,DBAASS.PROVA_QUESTAO.PRPQ_ARQU:pkg_null_blob.sf_null_blob,DBAASS.PROVA_QUESTAO.PRPQ_IMAG:pkg_null_blob.sf_null_blob,DBAASS.PROVA_QUESTAO.PRPQ_RIMG:pkg_null_blob.sf_null_blob,DBAASS.PUBLICACAO.PUBL_BLOB:pkg_null_blob.sf_null_blob,DBAASS.REBA_HIST_FUNDAMENTAL.RHFU_ARQU:pkg_null_blob.sf_null_blob,DBAASS.REBA_IES_HISTORICO.RIHI_ARQU:pkg_null_blob.sf_null_blob,DBAASS.REGISTRO_BOLETO_REMESSA.RBRM_BLOB:pkg_null_blob.sf_null_blob,DBAASS.REPOSICAO_TRABALHO.REPO_ARQU:pkg_null_blob.sf_null_blob,DBAASS.REPOSITORIO_PROVA.REPS_ARQU:pkg_null_blob.sf_null_blob,DBAASS.REPOSITORIO_PROVA_DOC.REDO_ARQU:pkg_null_blob.sf_null_blob,DBAASS.RETORNO_COBRANCA_TERC.ARET_ARQU:pkg_null_blob.sf_null_blob,DBAASS.SCANNER_TEMP_DOCS.SCTD_ARQU:pkg_null_blob.sf_null_blob,DBAASS.TEMPLATE.TPTE_FTHM:pkg_null_blob.sf_null_blob,DBAASS.TEMPLATE.TPTE_IHTM:pkg_null_blob.sf_null_blob,DBAASS.TESTE_ARQUIVO.TEST_ARQU:pkg_null_blob.sf_null_blob,DBAASS.TESTE_LAERCIO.BLOB_TESTE:pkg_null_blob.sf_null_blob,DBAASS.VM_ALUNO_TITULO_RENEG_2012.ALUN_ACOM:pkg_null_blob.sf_null_blob,DBAASS.VM_ALUN_RENEG_2012.ALUN_ACOM:pkg_null_blob.sf_null_blob,DBAASS.VM_BKP_BANCO_RETORNO_LOCALCRED.BARP_BLOB:pkg_null_blob.sf_null_blob,DBAASS.V_ALSE_FORMANDO.FORM_PROC:pkg_null_blob.sf_null_blob,DBAASS.V_AVALIACAO.AVAL_ARQU:pkg_null_blob.sf_null_blob,DBAASS.V_AVALIACAO_NEW.AVAL_ARQU:pkg_null_blob.sf_null_blob,DBAASS.V_AVALIACAO_OLD.AVAL_ARQU:pkg_null_blob.sf_null_blob,DBAASS.V_AVALIACAO_PROVA_AGRUP.AVAL_ARQU:pkg_null_blob.sf_null_blob,DBAASS.V_AVALIACAO_PROVA_AGRUPAMENTO.AVAL_ARQU:pkg_null_blob.sf_null_blob,DBAASS.V_AVALIACAO_PROVA_AGRUPAMENTO.PROP_ARDI:pkg_null_blob.sf_null_blob,DBAASS.V_AVALIACAO_PROVA_AGRUPA_NEW.AVAL_ARQU:pkg_null_blob.sf_null_blob,DBAASS.V_AVALIACAO_PROVA_AGRUPA_OLD.AVAL_ARQU:pkg_null_blob.sf_null_blob,DBAASS.V_AVALIACAO_PROVA_AGRUP_FULL.AVAL_ARQU:pkg_null_blob.sf_null_blob,DBAASS.V_AVALIACAO_TURMA.AVAL_ARQU:pkg_null_blob.sf_null_blob,DBAASS.V_AVALIACAO_TURMA_DOCUMENTO.ATDO_ARQU:pkg_null_blob.sf_null_blob,DBAASS.V_AVALIACAO_TURMA_NEW.AVAL_ARQU:pkg_null_blob.sf_null_blob,DBAASS.V_AVALIACAO_TURMA_OLD.AVAL_ARQU:pkg_null_blob.sf_null_blob,DBAASS.V_BIB_ALUN.IMAG:pkg_null_blob.sf_null_blob,DBAASS.V_CURSO_ETAPA.CURS_CARI:pkg_null_blob.sf_null_blob,DBAASS.V_CURSO_ETAPA.CURS_DIPL:pkg_null_blob.sf_null_blob,DBAASS.V_CURSO_ETAPA.CURS_IMAG:pkg_null_blob.sf_null_blob,DBAASS.V_CURSO_ETAPA.CURS_LOGO:pkg_null_blob.sf_null_blob,DBAASS.V_ESTAGIO_ALUNO.EDOC_ARQU:pkg_null_blob.sf_null_blob,DBAASS.V_FORMANDO.FORM_PROC:pkg_null_blob.sf_null_blob,DBAASS.V_PESSOA_FOTO.PDOC_IMAG:pkg_null_blob.sf_null_blob,DBAASS.V_PRODUCAO_ACAD_PRESENCIAL.PRAC_ARQU:pkg_null_blob.sf_null_blob,DBAASS.V_PROVA_AGRUPAMENTO.PROP_ARDI:pkg_null_blob.sf_null_blob,DBAASS.V_TESTE_LAERCIO.BLOB_TESTE:pkg_null_blob.sf_null_blob,DBAASS.X_ELEMENTO_ESTRUTURA.ELEE_CODF:pkg_null_blob.sf_null_blob,DBAASS.X_PRODUCAO_ACADEMICA_TEMP.ARQUIVO_IMPORTADO:pkg_null_blob.sf_null_blob,NFSE_EAD.CANCNFSE.XMLENV:pkg_null_blob.sf_null_blob,NFSE_EAD.CANCNFSE.XMLENVEXT:pkg_null_blob.sf_null_blob,NFSE_EAD.CANCNFSE.XMLRET:pkg_null_blob.sf_null_blob,NFSE_EAD.DOCUMENTOAUXILIAR.XMLDADOS:pkg_null_blob.sf_null_blob,NFSE_EAD.EMITENTE.KSTDAT:pkg_null_blob.sf_null_blob,NFSE_EAD.EMITENTE.LOGO:pkg_null_blob.sf_null_blob,NFSE_EAD.ENTRYDOC.MESSAGE:pkg_null_blob.sf_null_blob,NFSE_EAD.EVENTO.XMLENVIO:pkg_null_blob.sf_null_blob,NFSE_EAD.EVENTO.XMLEXTENDIDO:pkg_null_blob.sf_null_blob,NFSE_EAD.EVENTO.XMLRETORNO:pkg_null_blob.sf_null_blob,NFSE_EAD.LOTENFSE.DATA:pkg_null_blob.sf_null_blob,NFSE_EAD.LOTENFSE.XMLRECIBO:pkg_null_blob.sf_null_blob,NFSE_EAD.NFSE.XMLENVIO:pkg_null_blob.sf_null_blob,NFSE_EAD.NFSE.XMLEXTENDIDO:pkg_null_blob.sf_null_blob,NFSE_EAD.NFSE.XMLNFSE:pkg_null_blob.sf_null_blob,NFSE_EAD.NFSE.XMLRETORNO:pkg_null_blob.sf_null_blob,NFSE_EAD.OUTPUTQUEUEDOC.MESSAGE:pkg_null_blob.sf_null_blob,NFSE_EAD.SEFAZ_MESSAGE.CONTENT:pkg_null_blob.sf_null_blob,NFSE_NDD.EMITENTE.KSTDAT:pkg_null_blob.sf_null_blob,NFSE_NDD.EMITENTE.LOGO:pkg_null_blob.sf_null_blob,NFSE_NDD.NFSE.XMLENVIO:pkg_null_blob.sf_null_blob,NFSE_NDD.NFSE.XMLEXTENDIDO:pkg_null_blob.sf_null_blob,NFSE_NDD.NFSE.XMLNFSE:pkg_null_blob.sf_null_blob,NFSE_NDD.NFSE.XMLRETORNO:pkg_null_blob.sf_null_blob,NFSE_NDD.NFSE.XMLRPS:pkg_null_blob.sf_null_blob,NFSE_NEAD.CANCNFSE.XMLENV:pkg_null_blob.sf_null_blob,NFSE_NEAD.CANCNFSE.XMLENVEXT:pkg_null_blob.sf_null_blob,NFSE_NEAD.CANCNFSE.XMLRET:pkg_null_blob.sf_null_blob,NFSE_NEAD.DOCUMENTOAUXILIAR.XMLDADOS:pkg_null_blob.sf_null_blob,NFSE_NEAD.EMITENTE.KSTDAT:pkg_null_blob.sf_null_blob,NFSE_NEAD.EMITENTE.LOGO:pkg_null_blob.sf_null_blob,NFSE_NEAD.ENTRYDOC.MESSAGE:pkg_null_blob.sf_null_blob,NFSE_NEAD.EVENTO.XMLENVIO:pkg_null_blob.sf_null_blob,NFSE_NEAD.EVENTO.XMLEXTENDIDO:pkg_null_blob.sf_null_blob,NFSE_NEAD.EVENTO.XMLRETORNO:pkg_null_blob.sf_null_blob,NFSE_NEAD.FORNECEDOR_XSD.XSLMAP:pkg_null_blob.sf_null_blob,NFSE_NEAD.LOTENFSE.DATA:pkg_null_blob.sf_null_blob,NFSE_NEAD.LOTENFSE.XMLRECIBO:pkg_null_blob.sf_null_blob,NFSE_NEAD.NFSE.XMLENVIO:pkg_null_blob.sf_null_blob,NFSE_NEAD.NFSE.XMLEXTENDIDO:pkg_null_blob.sf_null_blob,NFSE_NEAD.NFSE.XMLNFSE:pkg_null_blob.sf_null_blob,NFSE_NEAD.NFSE.XMLRETORNO:pkg_null_blob.sf_null_blob,NFSE_NEAD.NFSE.XMLRPS:pkg_null_blob.sf_null_blob,NFSE_NEAD.OUTPUTQUEUEDOC.MESSAGE:pkg_null_blob.sf_null_blob,NFSE_NEAD.SEFAZ_MESSAGE.CONTENT:pkg_null_blob.sf_null_blob,NFSE_POS.CANCNFSE.XMLENV:pkg_null_blob.sf_null_blob,NFSE_POS.CANCNFSE.XMLENVEXT:pkg_null_blob.sf_null_blob,NFSE_POS.CANCNFSE.XMLRET:pkg_null_blob.sf_null_blob,NFSE_POS.DOCUMENTOAUXILIAR.XMLDADOS:pkg_null_blob.sf_null_blob,NFSE_POS.EMITENTE.KSTDAT:pkg_null_blob.sf_null_blob,NFSE_POS.EMITENTE.LOGO:pkg_null_blob.sf_null_blob,NFSE_POS.ENTRYDOC.MESSAGE:pkg_null_blob.sf_null_blob,NFSE_POS.EVENTO.XMLENVIO:pkg_null_blob.sf_null_blob,NFSE_POS.EVENTO.XMLEXTENDIDO:pkg_null_blob.sf_null_blob,NFSE_POS.EVENTO.XMLRETORNO:pkg_null_blob.sf_null_blob,NFSE_POS.FORNECEDOR_XSD.XSLMAP:pkg_null_blob.sf_null_blob,NFSE_POS.LOTENFSE.DATA:pkg_null_blob.sf_null_blob,NFSE_POS.LOTENFSE.XMLRECIBO:pkg_null_blob.sf_null_blob,NFSE_POS.NFSE.XMLENVIO:pkg_null_blob.sf_null_blob,NFSE_POS.NFSE.XMLEXTENDIDO:pkg_null_blob.sf_null_blob,NFSE_POS.NFSE.XMLNFSE:pkg_null_blob.sf_null_blob,NFSE_POS.NFSE.XMLRETORNO:pkg_null_blob.sf_null_blob,NFSE_POS.NFSE.XMLRPS:pkg_null_blob.sf_null_blob,NFSE_POS.OUTPUTQUEUEDOC.MESSAGE:pkg_null_blob.sf_null_blob,NFSE_POS.SEFAZ_MESSAGE.CONTENT:pkg_null_blob.sf_null_blob,OPENFIRE.DAVINCITALK_VERSAO.DVTA_INST:pkg_null_blob.sf_null_blob,OPENFIRE.OFRRDS.BYTES:pkg_null_blob.sf_null_blob,POS_EAD.POS_DOC_TCC.DTCC_ARQU:pkg_null_blob.sf_null_blob,POS_EAD.X_POS_TAR_ANEXOS.TAAN_ARQU:pkg_null_blob.sf_null_blob LOGFILE=EXP_PROD_SEM_BLOB.log